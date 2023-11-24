// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

// Interfaces
import {IHangar18} from "./IHangar18.sol";

/**
 *  @notice Simple interface for Cygnus Vault tokens (CygUSD and CygLP) with functions only needed for the harvester
 */
interface ICygnusTerminal {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
           3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return hangar18 The address of the Cygnus Factory contract used to deploy this shuttle
     */
    function hangar18() external view returns (IHangar18);

    /**
     *  @return underlying The address of the underlying (LP Token for collateral contracts, USDC for borrow contracts)
     */
    function underlying() external view returns (address);

    /**
     *  @return shuttleId The ID of this shuttle (shared by Collateral and Borrow)
     */
    function shuttleId() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Get the pending rewards manually - helpful to get rewards through static calls
     *
     *  @return tokens The addresses of the reward tokens earned by harvesting rewards
     *  @return amounts The amounts of each token received
     *
     *  @custom:security non-reentrant
     */
    function getRewards() external returns (address[] memory tokens, uint256[] memory amounts);

    /**
     *  @notice Only the harvester can reinvest
     *  @notice Reinvests all rewards from the rewarder to buy more USD to then deposit back into the rewarder
     *          This makes totalBalance increase in this contract, increasing the exchangeRate between
     *          CygUSD and underlying and thus lowering utilization rate and borrow rate
     *
     *  @custom:security only-harvester
     */
    function reinvestRewards_y7b(uint256 liquidity) external;
}
