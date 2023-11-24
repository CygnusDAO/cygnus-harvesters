// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

import {IHangar18} from "./IHangar18.sol";

// Vault
interface ICygnusX1Vault {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when withdrawing more than user balance
     *  @custom:error AmountExceedsBalance
     */
    error CygnusX1Vault__AmountExceedsBalance();

    /**
     *  @dev Reverts when msg.sender is not admin
     *  @custom:error MsgSenderNotAdmin
     */
    error CygnusX1Vault__MsgSenderNotAdmin();

    /**
     *  @dev Reverts when attempting to change state of a non-existing token 
     *  @custom:error InvalidRewardToken
     */
    error CygnusX1Vault__InvalidRewardToken();

    /**
     *  @dev Reverts when adding an already-added token
     *  @custom:error TokenAlreadyAdded
     */
    error CygnusX1Vault__TokenAlreadyAdded();

    /**
     *  @dev Reverts when the deposit fee set is above max
     *  @custom:error DepositFeeTooHigh
     */
    error CygnusX1Vault__DepositFeeTooHigh();

    /**
     *  @dev Reverts when adding more tokens than max allowed vault size
     *  @custom:error VaultIsFull
     */
    error CygnusX1Vault__VaultIsFull();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Emitted when a user deposits CYG
     *  @param user The address of the user that deposited
     *  @param amount The amount of CYG deposited
     *  @param fee The fee taken from the deposit
     */
    event Deposit(address indexed user, uint256 amount, uint256 fee);

    /**
     *  @notice Emitted when owner changes the deposit fee percentage
     *  @param newFee The new deposit fee percentage
     *  @param oldFee The old deposit fee percentage
     */
    event NewDepositFee(uint256 newFee, uint256 oldFee);

    /**
     *  @notice Emitted when a user withdraws CYG
     *  @param user The address of the withdrawing user
     *  @param amount The amount of CYG withdrawn
     */
    event Withdraw(address indexed user, uint256 amount);

    /**
     *  @notice Emitted when a user claims reward
     *  @param user The address of the user claiming rewards
     *  @param rewardToken The address of the reward token claimed
     *  @param amount The amount of the reward token claimed
     */
    event ClaimReward(address indexed user, address indexed rewardToken, uint256 amount);

    /**
     *  @notice Emitted when a user emergency withdraws from the vault
     *  @param user The address of the user performing the emergency withdraw
     *  @param amount The amount of CYG emergency withdrawn
     */
    event EmergencyWithdraw(address indexed user, uint256 amount);

    /**
     *  @notice Emitted when owner adds a token to the reward tokens list
     *  @param sender msg.sender
     *  @param vaultSize The vault size after this token was added
     *  @param token The address of the token added to the reward tokens list
     */
    event NewRewardToken(address sender, uint256 vaultSize, address token);

    /**
     *  @notice Emitted when owner removes a token from the reward tokens list
     *  @param token The address of the token removed from the reward tokens list
     */
    event RewardTokenRemoved(address token);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /** 
     *  @notice The name of the x1 vault
     */
    function name() external view returns (string memory);

    /**
     *  @notice Address of the hangar18 on this chain
     *  @return The hangar18
     */
    function hangar18() external view returns (IHangar18);

    /// @notice Accumulated `token` rewards per share, scaled to `ACC_REWARD_PER_SHARE_PRECISION`
    /// @param token The reward token address
    /// @return The reward per share for the given token
    function accRewardPerShare(address token) external view returns (uint256);

    /**
     *  @notice Indicates if a token is an active reward token
     *  @param token The reward token address
     *  @return True if token is an active reward token, false otherwise
     */
    function isRewardToken(address token) external view returns (bool);

    /**
     *  @notice Last reward balance of `token`
     *  @param token The reward token address
     *  @return The balance of the reward token
     */
    function lastRewardBalance(address token) external view returns (uint256);

    /**
     *  @notice The list of all active reward tokens
     *  @return The address array of all active reward tokens
     */
    function allRewardTokens(uint256) external view returns (address);

    /**
     *  @return The precision used to calculate rewards per share
     */
    function ACC_REWARD_PER_SHARE_PRECISION() external pure returns (uint256);

    /**
     *  @return The maximum number of reward tokens allowed
     */
    function MAX_REWARD_TOKENS() external pure returns (uint256);

    /**
     *  @return The maximum deposit fee percentage
     */
    function MAX_DEPOSIT_FEE() external pure returns (uint256);

    /**
     *  @return The address of the staking token (CYG)
     */
    function cygToken() external view returns (address);

    /**
     *  @return The current balance of staked CYG
     */
    function cygStakedBalance() external view returns (uint256);

    /**
     *  @return The deposit fee (if any)
     */
    function x1DepositFee() external view returns (uint256);

    /**
     *  @notice View function to see pending reward token
     *  @param user The address of the user
     *  @param token The address of the token
     *  @return Pending amount of `token` to be collected by `user`
     */
    function pendingReward(address user, address token) external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Update reward variables
     *  @param token The address of the reward token
     *  @dev Needs to be called before any deposit or withdrawal
     */
    function updateReward(address token) external;

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Deposit CYG for reward token allocation
     *  @param cygAmount The amount of CYG to deposit
     */
    function deposit(uint256 cygAmount) external;

    /**
     *  @notice Withdraw CYG and harvest the rewards
     *  @param _amount The amount of CYG to withdraw
     */
    function withdraw(uint256 _amount) external;

    /**
     *  @notice Add a reward token
     *  @param token The address of the reward token
     *  @custom:security only-admin
     */
    function addRewardToken(address token) external;

    /**
     *  @notice Remove a reward token
     *  @param token The address of the reward token
     *  @custom:security only-admin
     */
    function removeRewardToken(address token) external;

    /**
     *  @notice Set the deposit fee percent
     *  @param fee The new deposit fee percent
     *  @custom:security only-admin
     */
    function setNewDepositFee(uint256 fee) external;

    /**
     *  @notice Withdraws CYG without caring about rewards
     */
    function emergencyWithdraw() external;
}
