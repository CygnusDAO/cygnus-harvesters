# Cygnus 1Inch Harvester

This repo contains all harvesters used in Cygnus.

Since all capital deposited in core contracts are earning rewards, the core contracts allow external contracts called "Harvesters" to compound rewards into more LPs (for collaterals) or more stablecoins (for borrowables).

The harvesters are integrated with 1inch and are permissionless, callable by anyone to reinvest rewards and earn a percentage from the rewards.

## CygnusHarvester.sol

The main logic of each harvester is in the abstract contract `CygnusHarvester.sol` and all harvesters inherit from it. 

To swap all tokens with 1inch the contract uses 1Inch swap's legacy method.

```javascript
    /**
     *  @notice Creates the swap with 1Inch's AggregatorV5. We pass an extra param `updatedAmount` to eliminate
     *          any slippage from the byte data passed.
     *  @param swapdata The data from 1inch `swap` query
     *  @param srcAmount The balanceOf this contract`s srcToken
     *  @return amountOut The amount received of destination token
     */
    function _swapTokensOneInch(
        bytes calldata swapdata,
        address srcToken,
        uint256 srcAmount,
        address dstToken,
        address receiver
    ) internal returns (uint256 amountOut) {
        // Get aggregation executor, swap params and the encoded calls for the executor from 1inch API call
        (address caller, IAggregationRouterV5.SwapDescription memory desc, , bytes memory data) = abi.decode(
            swapdata,
            (address, IAggregationRouterV5.SwapDescription, bytes, bytes)
        );

        // Update swap amount to current balance of src token (if needed)
        if (desc.amount != srcAmount) desc.amount = srcAmount;

        /// @custom:error SrcTokenNotValid Avoid swapping anything but the harvested token
        if (address(desc.srcToken) != srcToken) revert CygnusHarvester__SrcTokenNotValid();

        /// @custom:error DstTokenNotValid Avoid swapping to anything but the harvester's want token
        if (address(desc.dstToken) != dstToken) revert CygnusHarvester__DstTokenNotValid();

        /// @custom:error DstReceiverNotValid Avoid swapping to anyone but the harvester's receiver address
        if (desc.dstReceiver != receiver) revert CygnusHarvester__DstReceiverNotValid();

        // Approve 1Inch Router in `srcToken` if necessary
        _approveToken(srcToken, ONE_INCH_ROUTER_V5, srcAmount);

        // Swap `srcToken` to `dstToken` passing empty permit bytes
        (amountOut, ) = IAggregationRouterV5(ONE_INCH_ROUTER_V5).swap(IAggregationExecutor(caller), desc, new bytes(0), data);
    }
```

## Examples

Since some borrowables use Compound Finance III as a strategy, unused USDC is deposited in the Compound USDC Market, earning from interest and COMP. The core contracts allow the harvesters to harvest the COMP, convert to USDC, and deposit all USDC into the vault again.

See `CompHarvester.sol` for example.

```javascript
    /// @notice Reinvests rewards from the terminal token into more underlying
    /// @param swapdata Array of bytes for the swaps
    /// @param borrowable The address of the borrowable we are reinvesting
    /// @return liquidity The amount of underlying we have reinvested
    function reinvestRewards(bytes[] calldata swapdata, address borrowable) external nonReentrant returns (uint256 liquidity) {
        // ─────────────────────── 1. Get harvester
        // Load to storage for gas savings, since we are not doign any writes
        Harvester storage harvester = harvesters[borrowable];

        /// @custom:error HarvesterNotSet Avoid if harvester is not set
        if (harvester.underlying == address(0)) revert CygnusHarvester__HarvesterNotSet();

        // ─────────────────────── 2. Harvest tokens from the terminal
        // Harvest rewards from the borrowable
        (address[] memory tokens, uint256[] memory amounts) = ICygnusTerminal(harvester.terminal).getRewards();

        // ─────────────────────── 3. Swap reward to the harvester's `wantToken`
        // Loop through each token reward
        for (uint256 i = 0; i < tokens.length; ) {
            // If token is not want and we have rewards swap
            if (amounts[i] > 0 && isRewardToken[tokens[i]]) {
                // Transfer token from Borrowable
                tokens[i].safeTransferFrom(harvester.terminal, address(this), amounts[i]);

                // Process rewards for X1 Vault
                uint256 finalAmount = _processX1Rewards(tokens[i], amounts[i]);

                // Check that token is not wantToken
                if (tokens[i] != harvester.wantToken) {
                    // Pass swap data `i` along with the token to be swapped
                    liquidity += _swapTokensOneInch(
                        // The swap data for token `i` from harvested rewards
                        swapdata[i],
                        // The token being swapped
                        tokens[i],
                        // The amount of token `i` we are swapping to wantToken
                        finalAmount,
                        // The token we should be receiving.
                        harvester.wantToken,
                        // Receiver
                        harvester.receiver
                    );
                }
                // token is wantToken, add to `wantAmount`
                else liquidity += finalAmount;
            }

            unchecked {
                ++i;
            }
        }

        // ─────────────────────── 5. Reinvest Rewards
        // Reinvest rewards in core, minting 0 shares and increasing totalBalance.
        ICygnusTerminal(harvester.terminal).reinvestRewards_y7b(liquidity);
    }
```
