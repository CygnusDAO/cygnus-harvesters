//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusHarvester.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
/*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  
    .               .            .               .      🛰️     .           .                .           .
           █████████           ---======*.                                                 .           ⠀
          ███░░░░░███                                               📡                🌔                         . 
         ███     ░░░  █████ ████  ███████ ████████   █████ ████  █████        ⠀
        ░███         ░░███ ░███  ███░░███░░███░░███ ░░███ ░███  ███░░      .     .⠀           .          
        ░███          ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███ ░░█████       ⠀
        ░░███     ███ ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███  ░░░░███              .             .⠀
         ░░█████████  ░░███████ ░░███████ ████ █████ ░░████████ ██████     .----===*  ⠀
          ░░░░░░░░░    ░░░░░███  ░░░░░███░░░░ ░░░░░   ░░░░░░░░ ░░░░░░            .                            .⠀
                       ███ ░███  ███ ░███                .                 .                 .  ⠀
     🛰️  .             ░░██████  ░░██████                                             .                 .           
                       ░░░░░░    ░░░░░░      -------=========*                      .                     ⠀
           .                            .       .          .            .                          .             .⠀
    
        CYGNUS HARVESTER - `QUICKSWAP HARVESTER (HYPERVISOR)`                                                           
    ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  */
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusHarvester, CygnusHarvester} from "./CygnusHarvester.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";

// Libraries
import {SafeTransferLib} from "./libraries/SafeTransferLib.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

// Interfaces
import {IERC20} from "./interfaces/core/IERC20.sol";
import {IHangar18} from "./interfaces/core/IHangar18.sol";
import {ICygnusTerminal} from "./interfaces/core/ICygnusTerminal.sol";
import {ICygnusNebulaRegistry} from "./interfaces/core/ICygnusNebulaRegistry.sol";
import {IGammaProxy, IHypervisor} from "./interfaces/IHypervisor.sol";
import {IAlgebraPool} from "./interfaces/IAlgebraPool.sol";

/// @title AlgebraHarvester
/// @author CygnusDAO
/// @notice Harvester fo algebra pools
contract AlgebraHarvester is CygnusHarvester {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @custom:library SafeTransferLib For safe transfers of Erc20 tokens
    using SafeTransferLib for address;

    /// @custom:library FixedPointMathLib Arithmetic library with operations for fixed-point numbers
    using FixedPointMathLib for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Public ─────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusHarvester
     */
    string public override name = "Cygnus: Algebra Harvester (Hypervisor)";

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Constructs the harvester, use the hangar18 contract to get important addresses
     *  @param _hangar18 The address of the contract that deploys Cygnus lending pools on this chain
     */
    constructor(IHangar18 _hangar18) CygnusHarvester(_hangar18) {}

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ───────────────────────────────────────────── Internal ────────────────────────────────────────────────  */

    ///  @notice Returns the weight of each asset in the LP
    ///  @param lpTokenPair The address of the LP
    ///  @return weight0 The weight of token0 in the LP
    ///  @return weight1 The weight of token1 in the LP
    function _tokenWeights(
        address lpTokenPair,
        address token0,
        address token1,
        address gammaUniProxy
    ) private view returns (uint256 weight0, uint256 weight1) {
        // Get scalars of each toekn
        uint256 scalar0 = 10 ** IERC20(token0).decimals();
        uint256 scalar1 = 10 ** IERC20(token1).decimals();

        // Calculate difference in units
        uint256 scalarDifference = scalar0.divWad(scalar1);

        // Adjust for token decimals
        uint256 decimalsDenominator = scalarDifference > 1e12 ? 1e6 : scalarDifference;

        // Get sqrt price from Algebra pool
        (uint256 sqrtPriceX96, , , , , , ) = IAlgebraPool(IHypervisor(lpTokenPair).pool()).globalState();

        // Convert to price with scalar diff and denom to take into account decimals of tokens
        uint256 price = ((sqrtPriceX96 ** 2 * (scalarDifference / decimalsDenominator)) / (2 ** 192)) * decimalsDenominator;

        // How much we would need to deposit of token1 if we are depositing 1 unit of token0
        (uint256 low1, uint256 high1) = IGammaProxy(gammaUniProxy).getDepositAmount(lpTokenPair, token0, scalar0);

        // Final token1 amount
        uint256 token1Amount = ((low1 + high1) / 2).divWad(scalar1);

        // Get ratio
        uint256 ratio = token1Amount.divWad(price);

        // Return weight of token0 in the LP
        weight0 = 1e36 / (ratio + 1e18);

        // Weight of token1
        weight1 = 1e18 - weight0;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ───────────────────────────────────────────── Internal ────────────────────────────────────────────────  */

    /// @notice Get the token amounts to deposit in the LP
    /// @param lpTokenPair The address of the gamma LP
    /// @param amount The usd amount
    /// @return amount0 The amount of token0 to deposit
    /// @return amount1 The amount of token1 to deposit
    function _getTokenAmounts(
        address lpTokenPair,
        address token0,
        address token1,
        address gammaUniProxy,
        uint256 amount
    ) internal view returns (uint256 amount0, uint256 amount1) {
        // Get the token weights
        (uint256 weight0, uint256 weight1) = _tokenWeights(lpTokenPair, token0, token1, gammaUniProxy);

        // Amount of usd to swap to token0
        amount0 = weight0.mulWad(amount);

        // Amount of usd to swap to token1
        amount1 = weight1.mulWad(amount);
    }

    /// @notice By now we would have converted 100% of the rewards into token0 or token1, we swap optimally to another token to the other to mint LP
    /// @param token0 The address of token0 from the LP Token
    /// @param token1 The address of token1 from the LP Token
    /// @param wantAmount The amount of want token to convert
    /// @param swapdata Bytes array consisting of 1inch API swap data
    /// @param lpTokenPair The address of the LP Token
    function _swapToLPAmounts(
        address token0,
        address token1,
        address wantToken,
        uint256 wantAmount,
        bytes[] calldata swapdata,
        address lpTokenPair,
        address receiver,
        address gammaUniProxy
    ) internal {
        // Get optimal amounts of token0 and token1
        (uint256 amount0, uint256 amount1) = _getTokenAmounts(lpTokenPair, token0, token1, gammaUniProxy, wantAmount);

        // Swap token0 to token1
        // prettier-ignore
        if (wantToken == token0) _swapTokensOneInch(swapdata[swapdata.length - 1], wantToken, amount1, token1, receiver);
        // Swap token1 to token0
        else if (wantToken == token1) _swapTokensOneInch(swapdata[swapdata.length - 1], wantToken, amount0, token0, receiver);
    }

    /// @notice This function gets called after calling `borrow` on Borrow contract and having `amountUsd` of USD
    /// @param token0 The address of token0 from the LP Token
    /// @param token1 The address of token1 from the LP Token
    /// @param lpTokenPair The address of the lp token
    /// @return liquidity The amount of LP minted
    function _mintLiquidity(address token0, address token1, address lpTokenPair, address receiver) internal returns (uint256 liquidity) {
        // Check balance of token0
        uint256 deposit0 = _checkBalance(token0);

        // Balance of token1
        uint256 deposit1 = _checkBalance(token1);

        // Approve token0 in hypervisor
        _approveToken(token0, lpTokenPair, deposit0);

        // Approve token1 in hypervisor
        _approveToken(token1, lpTokenPair, deposit1);

        // Get the whitelsited address - the only one allowed to deposit in hypervisor
        address gammaUniProxy = IHypervisor(lpTokenPair).whitelistedAddress();

        // Get the minimum and maximum limit of token1 deposit given our balance of token0
        (uint256 low1, uint256 high1) = IGammaProxy(gammaUniProxy).getDepositAmount(lpTokenPair, token0, deposit0);

        // If our balance of token1 is lower than the limit, get the limit of token0
        if (deposit1 < low1) {
            // Get the high limit of token0
            (, uint256 high0) = IGammaProxy(gammaUniProxy).getDepositAmount(lpTokenPair, token1, deposit1);

            // If balance of token0 is higher than limit then deposit high limit
            if (deposit0 > high0) deposit0 = high0;
        }

        // If our balance of token1 is higher than the limit, then deposit high limit
        if (deposit1 > high1) deposit1 = high1;

        // Mint LP
        liquidity = IGammaProxy(gammaUniProxy).deposit(deposit0, deposit1, receiver, lpTokenPair, [uint256(0), 0, 0, 0]);
    }

    /*  ───────────────────────────────────────────── External ────────────────────────────────────────────────  */

    /// @notice Reinvests rewards from the terminal token into more underlying
    /// @param swapdata Array of bytes for the swaps
    /// @param collateral The address of the collateral we are reinvesting
    /// @return liquidity The amount of underlying we have reinvested
    function reinvestRewards(bytes[] calldata swapdata, address collateral) external nonReentrant returns (uint256 liquidity) {
        // ─────────────────────── 1. Get harvester
        // Load to storage for gas savings, since we are not doing any writes
        Harvester storage harvester = harvesters[collateral];

        /// @custom:error HarvesterNotSet Avoid if harvester is not set
        if (harvester.underlying == address(0)) revert CygnusHarvester__HarvesterNotSet();

        // ─────────────────────── 2. Harvest tokens from the terminal
        // Harvest rewards from the collateral
        (address[] memory tokens, uint256[] memory amounts) = ICygnusTerminal(harvester.terminal).getRewards();

        // ─────────────────────── 3. Swap reward to the harvester's `wantToken`
        // Loop through each token reward
        for (uint256 i = 0; i < tokens.length; ) {
            // If token is not want and we have rewards swap
            if (amounts[i] > 0 && isRewardToken[tokens[i]]) {
                // Transfer token from Collateral
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

        /// Revert if no liquidity to reinvest
        if (liquidity == 0) revert("Insufficient want");

        // ─────────────────────── 4. Convert amount received of wantToken to liquidity
        // Tokens of underlying
        address token0 = IHypervisor(harvester.underlying).token0();
        address token1 = IHypervisor(harvester.underlying).token1();

        // Get the whitelsited address - the only one allowed to deposit in hypervisor
        address gammaUniProxy = IHypervisor(harvester.underlying).whitelistedAddress();

        // Swap tokens
        _swapToLPAmounts(token0, token1, harvester.wantToken, liquidity, swapdata, harvester.underlying, harvester.receiver, gammaUniProxy);

        // Convert token0 and token1 to liquidity
        liquidity = _mintLiquidity(token0, token1, harvester.underlying, harvester.terminal);

        // ─────────────────────── 5. Reinvest Rewards
        // Reinvest rewards in core, minting 0 shares and increasing totalBalance. By depositing more LPs to the collateral
        // we are decreasing all borrower`s debt ratio as they now own more collateral claim more collateral
        ICygnusTerminal(harvester.terminal).reinvestRewards_y7b(liquidity);
    }
}
