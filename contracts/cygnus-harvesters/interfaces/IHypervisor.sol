// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.17;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3Pool {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

interface IHypervisor {
    function getTotalAmounts() external view returns (uint256 total0, uint256 total1);

    function getBasePosition() external view returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    function baseLower() external view returns (int24);

    function baseUpper() external view returns (int24);

    function limitLower() external view returns (int24);

    function limitUpper() external view returns (int24);

    function pool() external view returns (address);

    function totalSupply() external view returns (uint256);

    /// @param shares Number of liquidity tokens to redeem as pool assets
    /// @param to Address to which redeemed pool assets are sent
    /// @param from Address from which liquidity tokens are sent
    /// @param minAmounts min amount0,1 returned for shares of liq
    /// @return amount0 Amount of token0 redeemed by the submitted liquidity tokens
    /// @return amount1 Amount of token1 redeemed by the submitted liquidity tokens
    function withdraw(
        uint256 shares,
        address to,
        address from,
        uint256[4] memory minAmounts
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Deposit tokens
    /// @param deposit0 Amount of token0 transfered from sender to Hypervisor
    /// @param deposit1 Amount of token1 transfered from sender to Hypervisor
    /// @param to Address to which liquidity tokens are minted
    /// @param from Address from which asset tokens are transferred
    /// @param inMin min spend for directDeposit is true
    /// @return shares Quantity of liquidity tokens minted as a result of deposit
    function deposit(
        uint256 deposit0,
        uint256 deposit1,
        address to,
        address from,
        uint256[4] memory inMin
    ) external returns (uint256 shares);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function whitelistedAddress() external view returns (address);
}

interface IGammaProxy {
    function deposit(
        uint256 deposit0,
        uint256 deposit1,
        address to,
        address pos,
        uint256[4] memory inMin
    ) external returns (uint256 liquidity);

    function getDepositAmount(address, address, uint256) external view returns (uint256, uint256);
}
