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
    
        CYGNUS HARVESTER - X1 Vault Base Harvester                                                           
    ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  */
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusHarvester} from "./interfaces/ICygnusHarvester.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";

// Libraries
import {SafeTransferLib} from "./libraries/SafeTransferLib.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

// Interfaces
import {IERC20} from "./interfaces/core/IERC20.sol";
import {IHangar18} from "./interfaces/core/IHangar18.sol";
import {ICygnusTerminal} from "./interfaces/core/ICygnusTerminal.sol";
import {ICygnusX1Vault} from "./interfaces/core/ICygnusX1Vault.sol";

// Aggregators
import {IAggregationRouterV5, IAggregationExecutor} from "./interfaces/aggregators/IAggregationRouterV5.sol";

/**
 *  @title CygnusHarvester
 *  @author CygnusDAO
 *  @notice Base harvester for both borrowable and collateral pools
 */
abstract contract CygnusHarvester is ICygnusHarvester, ReentrancyGuard {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library SafeTransferLib For safe transfers of Erc20 tokens
     */
    using SafeTransferLib for address;

    /**
     *  @custom:library FixedPointMathLib Arithmetic library with operations for fixed-point numbers
     */
    using FixedPointMathLib for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Public ─────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusHarvester
     */
    address public constant override ONE_INCH_ROUTER_V5 = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    /**
     *  @inheritdoc ICygnusHarvester
     */
    mapping(address => Harvester) public override harvesters;

    /**
     *  @inheritdoc ICygnusHarvester
     */
    address[] public override allRewardTokens;

    /**
     *  @inheritdoc ICygnusHarvester
     */
    mapping(address => bool) public isRewardToken;

    /**
     *  @inheritdoc ICygnusHarvester
     */
    uint256 public override lastX1Collect;

    /**
     *  @inheritdoc ICygnusHarvester
     */
    uint256 public override x1VaultReward = 0.22e18;

    /**
     *  @inheritdoc ICygnusHarvester
     */
    uint256 public override harvesterReward = 0.03e18;

    /**
     *  @inheritdoc ICygnusHarvester
     */
    IHangar18 public immutable override hangar18;

    /**
     *  @inheritdoc ICygnusHarvester
     */
    address public immutable override usd;

    /**
     *  @inheritdoc ICygnusHarvester
     */
    address public immutable override nativeToken;

    /**
     *  @inheritdoc ICygnusHarvester
     */
    address public immutable override cygnusX1Vault;

    /**
     *  @inheritdoc ICygnusHarvester
     */
    bool public override simpleHarvest;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Constructs the harvester, use the hangar18 contract to get important addresses
     *  @param _hangar18 The address of the contract that deploys Cygnus lending pools on this chain
     */
    constructor(IHangar18 _hangar18) {
        // Hangar18 on this chain
        hangar18 = _hangar18;

        // Get native token for this chain (ie WETH)
        nativeToken = _hangar18.nativeToken();

        // Get native token for this chain (ie WETH)
        usd = _hangar18.usd();

        // Vault
        cygnusX1Vault = _hangar18.cygnusX1Vault();
    }

    /**
     *  @dev This function is called for plain Ether transfers
     */
    receive() external payable {}

    /**
     *  @dev Fallback function is executed if none of the other functions match the function identifier or no data was provided
     */
    fallback() external payable {}

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. MODIFIERS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @custom:modifier cygnusAdmin Controls important parameters in both Collateral and Borrow contracts 👽
    modifier cygnusAdmin() {
        // If msg.sender not hangar18 admin then reverts tx
        checkAdminPrivate();
        _;
    }

    modifier onlyEOA() {
        // If msg.sender not tx.origin then reverts the tx
        checkEOAPrivate();
        _;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Checks that sender is admin
     */
    function checkAdminPrivate() private view {
        // Current admin from the factory
        address admin = hangar18.admin();

        /// @custom:error MsgSenderNotAdmin Avoid unless caller is Cygnus Admin
        if (msg.sender != admin) revert CygnusHarvester__MsgSenderNotAdmin();
    }

    /**
     *  @notice Checks that sender is origin
     */
    function checkEOAPrivate() private view {
        /// @custom:error CygnusHarvester__OnlyEOA Avoid unless caller is origin
        if (msg.sender != tx.origin) revert CygnusHarvester__OnlyEOAAllowed();
    }

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Checks the `token` balance of this contract
     *  @param token The token to view balance of
     *  @return amount This contract's `token` balance
     */
    function _checkBalance(address token) internal view returns (uint256) {
        // Our balance of `token`
        return token.balanceOf(address(this));
    }

    /*  ────────────────────────────────────────────── Public ─────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusHarvester
     */
    function rewardTokenBalanceAtIndex(uint256 index) public view override returns (uint256) {
        // Get our balance of reward token at `index`
        return _checkBalance(allRewardTokens[index]);
    }

    /**
     *  @inheritdoc ICygnusHarvester
     */
    function rewardTokensLength() public view override returns (uint256) {
        // Return the amount of tokens we are sending to X1 Vault
        return allRewardTokens.length;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Collects the reward token amount held by this contract and sends to vault
     *  @param rewardToken The address of the token we are approving
     */
    function collectX1RewardTokenPrivate(address rewardToken) private {
        // Get our balance of reward token `i`
        uint256 balance = _checkBalance(rewardToken);

        // Check for balance
        if (balance > 0) {
            // Transfer to the vault
            rewardToken.safeTransfer(cygnusX1Vault, balance);

            // Update reward in vault
            ICygnusX1Vault(cygnusX1Vault).updateReward(rewardToken);
        }
    }

    /**
     *  @notice Adds a reward token to be collected by the X1 Vault on this chain
     *  @param rewardToken The address of the token to be added
     */
    function addRewardTokenPrivate(address rewardToken) private {
        // Push reward token to array
        allRewardTokens.push(rewardToken);

        // Mark as true
        isRewardToken[rewardToken] = true;

        /// @custom:event NewX1RewardToken
        emit RewardTokenAdded(rewardToken, allRewardTokens.length);
    }

    /**
     *  @notice Removes a reward token from the harvester
     *  @param rewardToken The address of the token to be removed
     */
    function removeRewardTokenPrivate(address rewardToken) private {
        // Mark as false
        isRewardToken[rewardToken] = false;

        // Gas savings
        uint256 length = allRewardTokens.length;

        // Loop through each reward token
        for (uint256 i; i < length; i++) {
            // If token is found then we remove it
            if (allRewardTokens[i] == rewardToken) {
                // Move token to the last index of the array
                allRewardTokens[i] = allRewardTokens[length - 1];

                // Pop last index
                allRewardTokens.pop();

                // Escape
                break;
            }
        }

        /// @custom:event RewardTokenRemoved
        emit RewardTokenRemoved(rewardToken, allRewardTokens.length);
    }

    /*  ───────────────────────────────────────────── Internal ────────────────────────────────────────────────  */

    /**
     *  @notice Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract
     *  @param token The address of the token we are approving
     *  @param amount The amount to approve
     */
    function _approveToken(address token, address to, uint256 amount) internal {
        // Check allowance for `router` for deposit
        if (IERC20(token).allowance(address(this), to) >= amount) return;

        // Is less than amount, safe approve max
        token.safeApprove(to, type(uint256).max);
    }

    /**
     *  @notice Processes rewards for the caller of the harvest/reinvest and for the X1 Vault
     *  @param token The address of the rewardToken
     *  @param amount Our balance of `token`
     *  @return The amount of `token` left after processing rewards
     */
    function _processX1Rewards(address token, uint256 amount) internal returns (uint256) {
        // Calculate the amount that the X1 Vault receives
        uint256 x1Reward = amount.mulWad(x1VaultReward);

        // Transfer to the X1 Vault
        if (x1Reward > 0) token.safeTransfer(cygnusX1Vault, x1Reward);

        // Return balance left of the reward token that is left to be reinvested
        return _checkBalance(token);
    }

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

        /// @custom;error DstTokenNotValid Avoid swapping to anything but the harvester's want token
        if (address(desc.dstToken) != dstToken) revert CygnusHarvester__DstTokenNotValid();

        /// @custom:error DstReceiverNotValid Avoid swapping to anyone but the harvester's receiver address
        if (desc.dstReceiver != receiver) revert CygnusHarvester__DstReceiverNotValid();

        // Approve 1Inch Router in `srcToken` if necessary
        _approveToken(srcToken, ONE_INCH_ROUTER_V5, srcAmount);

        // Swap `srcToken` to `dstToken` passing empty permit bytes
        (amountOut, ) = IAggregationRouterV5(ONE_INCH_ROUTER_V5).swap(IAggregationExecutor(caller), desc, new bytes(0), data);
    }

    /*  ───────────────────────────────────────────── External ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusHarvester
     *  @custom:security only-admin
     */
    function getRewards(address terminal) external override nonReentrant returns (address[] memory tokens, uint256[] memory amounts) {
        // Tokens and amounts harvested
        (tokens, amounts) = ICygnusTerminal(terminal).getRewards();

        // Return the amounts to be reinvested by substracting the vault reward from the harvested amount.
        // The full amounts are accessible on the terminal contracts.
        for (uint256 i = 0; i < amounts.length; i++) {
            // Substract the harvested amount by the vault and harvester rewards
            amounts[i] -= amounts[i].mulWad(x1VaultReward);
        }
    }

    /**
     *  @inheritdoc ICygnusHarvester
     *  @custom:security only-admin
     */
    function harvestToX1Vault(address terminal) external virtual override nonReentrant {
        /// @custom;error SimpleHarvestNotEnabled Avoid if simple harvest has not been enabled yet
        if (!simpleHarvest) revert CygnusHarvester__SimpleHarvestNotEnabled();

        // Harvest rewards
        (address[] memory tokens, uint256[] memory amounts) = ICygnusTerminal(terminal).getRewards();

        // Loop through each token
        for (uint256 i = 0; i < tokens.length; i++) {
            // If amount `i` is greater than 0
            if (amounts[i] > 0 && isRewardToken[tokens[i]]) {
                // Caller reward
                uint256 harvesterAmount = amounts[i].mulWad(harvesterReward);

                // Transfer to harvester
                tokens[i].safeTransferFrom(terminal, msg.sender, harvesterAmount);

                // Transfer the rest to the vault
                tokens[i].safeTransferFrom(terminal, cygnusX1Vault, amounts[i] - harvesterAmount);

                // Update reward
                ICygnusX1Vault(cygnusX1Vault).updateReward(tokens[i]);
            }
        }
    }

    /**
     *  @inheritdoc ICygnusHarvester
     *  @custom:security only-admin
     */
    function collectX1RewardsAll() external override nonReentrant {
        // Gas savings, get all reward tokens
        address[] memory rewardTokens = allRewardTokens;

        // Loop through each reward token
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            // Check balance and send private
            collectX1RewardTokenPrivate(rewardTokens[i]);
        }

        /// @custom:event CygnusX1VaultCollect
        emit CygnusX1VaultCollect(lastX1Collect = block.timestamp, msg.sender, allRewardTokens.length);
    }

    /*  ──────────────────────────────────────────── ADMIN ONLY ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusHarvester
     *  @custom:security only-admin
     */
    function addRewardToken(address rewardToken) public override cygnusAdmin {
        /// @custom;error RewardTokenAlreadyAdded
        if (isRewardToken[rewardToken]) revert CygnusHarvester__RewardTokenAlreadyAdded();

        // Add reward token to array and mark it as true in mapping
        addRewardTokenPrivate(rewardToken);
    }

    /**
     *  @inheritdoc ICygnusHarvester
     *  @custom:security only-admin
     */
    function removeRewardToken(address rewardToken) public override cygnusAdmin {
        /// @custom;error RewardTokenNotAdded
        if (!isRewardToken[rewardToken]) revert CygnusHarvester__RewardTokenNotAdded();

        // Remove reward token from array and remove from mapping
        removeRewardTokenPrivate(rewardToken);
    }

    /**
     *  @inheritdoc ICygnusHarvester
     *  @custom:security only-admin
     */
    function setTerminalHarvester(address terminal, address wantToken, address receiver) external override cygnusAdmin {
        // Get the underlying
        address underlying = ICygnusTerminal(terminal).underlying();

        // Make harvester
        Harvester memory harvester = Harvester({underlying: underlying, terminal: terminal, wantToken: wantToken, receiver: receiver});

        // Set harvester
        harvesters[terminal] = harvester;

        /// @custom:event NewHarvester
        emit NewHarvester(terminal, underlying, wantToken, receiver);
    }

    /**
     *  @inheritdoc ICygnusHarvester
     *  @custom:security only-admin
     */
    function setWeightX1Vault(uint256 newWeight) external override cygnusAdmin {
        /// @custom:error X1VaultRewardTooHigh Avoid setting reward above 50%
        if (newWeight > 0.5e18) revert CygnusHarvester__X1VaultRewardTooHigh();

        // X1 Vault reward weight up until now
        uint256 oldWeight = x1VaultReward;

        /// @custom:event NewX1VaultWeight
        emit NewX1VaultWeight(oldWeight, x1VaultReward = newWeight);
    }

    /**
     *  @inheritdoc ICygnusHarvester
     *  @custom:security only-admin
     */
    function setWeightHarvester(uint256 newWeight) external override cygnusAdmin {
        /// @custom:error X1VaultRewardTooHigh Avoid setting reward above 10%
        if (newWeight > 0.1e18) revert CygnusHarvester__HarvestRewardTooHigh();

        // X1 Vault reward weight up until now
        uint256 oldWeight = harvesterReward;

        /// @custom:event NewX1VaultWeight
        emit NewHarvesterWeight(oldWeight, harvesterReward = newWeight);
    }

    /**
     *  @inheritdoc ICygnusHarvester
     *  @custom:security only-admin
     */
    function switchSimpleHarvest() external override cygnusAdmin {
        // Switch on/off
        simpleHarvest = !simpleHarvest;

        /// @custom:event SimpleHarvestSwitch
        emit SimpleHarvestSwitch(simpleHarvest);
    }
}
