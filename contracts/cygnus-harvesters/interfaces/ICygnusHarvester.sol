// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.17;

import {IHangar18} from "./core/IHangar18.sol";

// Interface to interact with harvester if needed
interface ICygnusHarvester {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @dev Reverts if msg.sender is not harvester admin
    /// @custom:error MsgSenderNotAdmin
    error CygnusHarvester__MsgSenderNotAdmin();

    /// @dev Reverts if harvester does not exist for a terminal token
    /// @custom:error HarvesterNotSet
    error CygnusHarvester__HarvesterNotSet();

    /// @dev Reverts if removing a reward token that is not yet added to the harvester
    /// @custom:error RewardTokenNotValid
    error CygnusHarvester__RewardTokenNotAdded();

    /// @dev Reverts if adding a token that is already set
    /// @custom:error RewardTokenAlreadyAdded
    error CygnusHarvester__RewardTokenAlreadyAdded();

    /// @dev Reverts if the src token being swapped is not the same as the one harvested
    /// @custom:error SrcTokenNotValid
    error CygnusHarvester__SrcTokenNotValid();

    /// @dev Reverts if the token received is not the harvester's want token
    /// @custom:error DstTokenNotValid
    error CygnusHarvester__DstTokenNotValid();

    /// @dev Reverts if the receiver is not the harvester's receiver
    /// @custom:error DstReceiverNotValid
    error CygnusHarvester__DstReceiverNotValid();

    /// @dev Reverts if the X1 Vault reward being set is above 50%
    /// @custom:error X1VaultRewardTooHigh
    error CygnusHarvester__X1VaultRewardTooHigh();

    /// @dev Reverts if Paraswap tx fails
    /// @custom:error ParaswapTransactionFailed
    error CygnusHarvester__ParaswapTransactionFailed();

    /// @dev Reverts when doing a simple harvest when its not enabled
    /// @custom:error SimpleHarvestNotEnabled
    error CygnusHarvester__SimpleHarvestNotEnabled();

    /// @dev Reverts when tx.origin is not msg.sender
    /// @custom:error OnlyEOAAllowed
    error CygnusHarvester__OnlyEOAAllowed();

    /// @dev Reverts when setting the harvester (EOA) reward above 10%
    /// @custom:error HarvestRewardTooHigh
    error CygnusHarvester__HarvestRewardTooHigh();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @dev Logs when a reward token is added
    /// @param token The address of the token being added
    /// @param length Total reward tokens this harvester has stored after adding token
    /// @custom:event RewardTokenAdded
    event RewardTokenAdded(address token, uint256 length);

    /// @dev Logs when a reward token is removed
    /// @param token The address of the token being removed
    /// @param length Total reward tokens this harvester has stored after removing token
    /// @custom:event RewardTokenRemoved
    event RewardTokenRemoved(address token, uint256 length);

    /// @notice Logs when a harvester is created
    /// @param terminal The address of borrowable/collateral
    /// @param underlying The address of the underlying asset for the terminal token
    /// @param wantToken The address of the token the harvester wants to swap to
    /// @param receiver The address of the receiver of the harvest
    /// @custom:event InitializeCollateralHarvester
    event NewHarvester(address terminal, address underlying, address wantToken, address receiver);

    /// @dev Logs when the x1 vault reward is updated
    /// @param oldWeight The old value of the x1 vault reward before the update
    /// @param newWeight The new value of the x1 vault reward after the update
    /// @custom:event NewX1VaultWeight
    event NewX1VaultWeight(uint256 oldWeight, uint256 newWeight);

    /// @dev Logs when the harvester reward is updated
    /// @param oldWeight The old value of the harvester reward before the update
    /// @param newWeight The new value of the harvester reward after the update
    /// @custom:event NewHarvesterWeight
    event NewHarvesterWeight(uint256 oldWeight, uint256 newWeight);

    /// @dev Logs when the X1 vault collects rewards
    /// @param timestamp The current timestamp of the collect
    /// @param sender The msg.sender
    /// @param tokensLength The amount of reward tokens we sent to vault (even if balance is 0)
    /// @custom:event CygnusX1VaultCollect
    event CygnusX1VaultCollect(uint256 timestamp, address sender, uint256 tokensLength);

    /// @dev Emits when the admin changes the harvest method
    /// @param _simpleHarvest Whether the simple harvest is on or off
    event SimpleHarvestSwitch(bool _simpleHarvest);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @dev Dex Aggregator enum (atm only 1inch is enabled, but good to have)
    enum DexAggregator {
        ONE_INCH,
        PARASWAP,
        OPEN_OCEAN
    }

    /// @dev The harvester struct
    /// @custom:member terminal The address of the collateral or borrowable
    /// @custom:member underlying The address of the underlying of the terminal (ie. a stablecoin or liquidity token)
    /// @custom:member wantToken The address of the token the harvester wants to swap rewards into (tokenA)
    /// @custom:member receiver The address of the receiver of the harvest
    struct Harvester {
        address terminal;
        address underlying;
        address wantToken;
        address receiver;
    }

    // @dev Address of the 1inch router used to reinvest
    function ONE_INCH_ROUTER_V5() external pure returns (address);

    /// @dev Returns the harvester for a given terminal token
    function harvesters(address terminal) external view returns (address, address, address, address);

    /// @dev Returns the reward token at `index`
    /// @param index The index in the array.
    /// @return The address of the reward token at the given index.
    function allRewardTokens(uint256 index) external view returns (address);

    /// @dev Returns whether the rewardToken is stored as a reward token
    /// @param rewardToken The address of the reward token
    /// @return Whether the rewardToken is being tracked or not
    function isRewardToken(address rewardToken) external view returns (bool);

    /// @dev Returns the name of the contract.
    /// @return The name of the contract.
    function name() external view returns (string memory);

    /// @return harvesterReward Reward that the caller of the harvest/reinvest receives from the reward tokens
    function harvesterReward() external view returns (uint256);

    /// @return harvesterReward Reward that the x1 vault receives from the reward tokens
    function x1VaultReward() external view returns (uint256);

    /// @notice Returns the timestamp of the last X1 Vault collect. Updates after
    /// @return Timestamp of the last collect
    function lastX1Collect() external view returns (uint256);

    /// @dev Returns the Hangar18 contract.
    /// @return The Hangar18 contract.
    function hangar18() external view returns (IHangar18);

    /// @dev Returns the address of the native token.
    /// @return The address of the native token.
    function nativeToken() external view returns (address);

    /// @dev Returns the address of usdc
    /// @return The address of usdc on this chain
    function usd() external view returns (address);

    /// @dev Returns the address of the CygnusX1Vault contract.
    /// @return The address of the CygnusX1Vault contract.
    function cygnusX1Vault() external view returns (address);

    /// @dev Returns the amount of reward tokens to be sent to the X1 Vault
    function rewardTokensLength() external view returns (uint256);

    /// @notice Returns the balance of the index token at the specified index.
    /// @notice Helpful to use in case we use a script or a collector function to get all reward tokens of the array
    /// @param index The index of the index token to check the balance of.
    /// @return The balance of the index token at the specified index.
    function rewardTokenBalanceAtIndex(uint256 index) external view returns (uint256);

    /// @notice Switches to simple harvest. If simple harvest is set, then the rewards are sent straight to the vault
    ///         instead of reinvested.
    function simpleHarvest() external view returns (bool);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @notice Gets the rewards from the terminalToken and returns an array of tokens with the amounts harvested.
    ///         The amounts harvested take into account the amount of the harvest sent to the X1 Vault.
    ///         This is helpful when querying how much we will be reinvesting into the terminal.
    /// @return tokens Array of tokens harvested
    /// @return amounts array of amounts harvested of each token
    /// @custom:security non-reentrant
    function getRewards(address terminalToken) external returns (address[] memory tokens, uint256[] memory amounts);

    /// @notice Harvests the rewards directly to the vault
    /// @dev simpleHarvest bool must be set or else tx reverts
    /// @custom:security non-reentrant
    function harvestToX1Vault(address terminal) external;

    /// @notice Collects all pending rewards of approved tokens and sends it to the X1 vault
    /// @custom:security non-reentrant
    function collectX1RewardsAll() external;

    /**  Admin 👽  **/

    ///  @notice Admin 👽
    ///  @notice Add a reward token to be collected by the X1 Vault
    ///  @param token The address of the token
    ///  @custom:security only-admin
    function addRewardToken(address token) external;

    ///  @notice Admin 👽
    ///  @notice Remove a reward token to be collected by the X1 Vault
    ///  @param token The address of the token
    ///  @custom:security only-admin
    function removeRewardToken(address token) external;

    /// @notice Admin 👽
    /// @param terminal The address of borrowable/collateral
    /// @param wantToken The address of the token the harvester wants to swap to
    /// @param receiver The address of the receiver of the harvest
    /// @custom:security only-admin
    function setTerminalHarvester(address terminal, address wantToken, address receiver) external;

    /// @notice Admin 👽
    /// @param weight The new weight being set for the x1 vault
    /// @custom:security only-admin
    function setWeightX1Vault(uint256 weight) external;

    /// @notice Admin 👽
    /// @param weight The new weight being set for the caller of the harvest
    /// @custom:security only-admin
    function setWeightHarvester(uint256 weight) external;

    /// @notice Admin 👽
    /// @notice Switches the harvest method. The contract allows for two types of harvests:
    ///         - harvestToVault - Harvests all rewards and sends straight to vault
    ///         - reinvestRewards - Harvests all rewards and compounds a percentage to the terminal (can be 100%)
    /// @custom:security only-admin
    function switchSimpleHarvest() external;
}
