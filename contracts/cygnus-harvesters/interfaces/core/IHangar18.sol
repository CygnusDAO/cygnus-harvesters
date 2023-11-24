//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  IHangar18.sol
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
pragma solidity >=0.8.17;

// Orbiters
import {ICygnusNebulaRegistry} from "./ICygnusNebulaRegistry.sol";

// Oracles

/**
 *  @title The interface for the Cygnus Factory
 *  @notice The Cygnus factory facilitates creation of collateral and borrow pools
 */
interface IHangar18 {

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Array of LP Token pairs deployed
     *  @param _shuttleId The ID of the shuttle deployed
     *  @return launched Whether this pair exists or not
     *  @return shuttleId The ID of this shuttle
     *  @return borrowable The address of the borrow contract
     *  @return collateral The address of the collateral contract
     *  @return orbiterId The ID of the orbiters used to deploy this lending pool
     */
    function allShuttles(
        uint256 _shuttleId
    ) external view returns (bool launched, uint88 shuttleId, address borrowable, address collateral, uint96 orbiterId);

    /**
     *  @notice Official record of all lending pools deployed
     *  @param _lpTokenPair The address of the LP Token
     *  @param _orbiterId The ID of the orbiter for this LP Token
     *  @return launched Whether this pair exists or not
     *  @return shuttleId The ID of this shuttle
     *  @return borrowable The address of the borrow contract
     *  @return collateral The address of the collateral contract
     *  @return orbiterId The ID of the orbiters used to deploy this lending pool
     */
    function getShuttles(
        address _lpTokenPair,
        uint256 _orbiterId
    ) external view returns (bool launched, uint88 shuttleId, address borrowable, address collateral, uint96 orbiterId);

    /**
     *  @return Human friendly name for this contract
     */
    function name() external view returns (string memory);

    /**
     *  @return The version of this contract
     */
    function version() external view returns (string memory);

    /**
     *  @return usd The address of the borrowable token (stablecoin)
     */
    function usd() external view returns (address);

    /**
     *  @return nativeToken The address of the chain's native token
     */
    function nativeToken() external view returns (address);

    /**
     *  @notice The address of the nebula registry on this chain
     */
    function nebulaRegistry() external view returns (ICygnusNebulaRegistry);

    /**
     *  @return admin The address of the Cygnus Admin which grants special permissions in collateral/borrow contracts
     */
    function admin() external view returns (address);

    /**
     *  @return pendingAdmin The address of the requested account to be the new Cygnus Admin
     */
    function pendingAdmin() external view returns (address);

    /**
     *  @return daoReserves The address that handles Cygnus reserves from all pools
     */
    function daoReserves() external view returns (address);

    /**
     * @dev Returns the address of the contract to be the new DAO reserves.
     * @return pendingDaoReserves The address of the requested contract to be the new DAO reserves.
     */
    function pendingDaoReserves() external view returns (address);

    /**
     * @dev Returns the address of the CygnusDAO revenue vault.
     * @return cygnusX1Vault The address of the CygnusDAO revenue vault.
     */
    function cygnusX1Vault() external view returns (address);

    /**
     * @dev Returns the total number of orbiter pairs deployed (1 collateral + 1 borrow = 1 orbiter).
     * @return orbitersDeployed The total number of orbiter pairs deployed.
     */
    function orbitersDeployed() external view returns (uint256);

    /**
     * @dev Returns the total number of shuttles deployed.
     * @return shuttlesDeployed The total number of shuttles deployed.
     */
    function shuttlesDeployed() external view returns (uint256);

    /**
     *  @dev Returns the chain ID
     */
    function chainId() external view returns (uint256);

    /**
     * @dev Returns the borrowable TVL (Total Value Locked) in USD for a specific shuttle.
     * @param shuttleId The ID of the shuttle for which the borrowable TVL is requested.
     * @return The borrowable TVL in USD for the specified shuttle.
     */
    function borrowableTvlUsd(uint256 shuttleId) external view returns (uint256);

    /**
     * @dev Returns the collateral TVL (Total Value Locked) in USD for a specific shuttle.
     * @param shuttleId The ID of the shuttle for which the collateral TVL is requested.
     * @return The collateral TVL in USD for the specified shuttle.
     */
    function collateralTvlUsd(uint256 shuttleId) external view returns (uint256);

    /**
     * @dev Returns the total TVL (Total Value Locked) in USD for a specific shuttle.
     * @param shuttleId The ID of the shuttle for which the total TVL is requested.
     * @return The total TVL in USD for the specified shuttle.
     */
    function shuttleTvlUsd(uint256 shuttleId) external view returns (uint256);

    /**
     * @dev Returns the USD value of the DAO Cyg LP reserves.
     * @return The USD value of the DAO Cyg LP reserves.
     */
    function daoCygLPReservesUsd() external view returns (uint256);

    /**
     * @dev Returns the USD value of the DAO Cyg USD reserves.
     * @return The USD value of the DAO Cyg USD reserves.
     */
    function daoCygUsdReservesUsd() external view returns (uint256);

    /**
     * @dev Returns the total USD value of CygnusDAO reserves.
     * @return The total USD value of CygnusDAO reserves.
     */
    function cygnusTotalReservesUsd() external view returns (uint256);

    /**
     * @dev Returns the total amount borrowed in USD.
     * @return The total amount borrowed in USD.
     */
    function totalBorrowsUsd() external view returns (uint256);

    /**
     * @dev Returns the total borrowable TVL (Total Value Locked) in USD for all shuttles.
     * @return The total borrowable TVL in USD.
     */
    function allBorrowablesTvlUsd() external view returns (uint256);

    /**
     * @dev Returns the total collateral TVL (Total Value Locked) in USD for all shuttles.
     * @return The total collateral TVL in USD.
     */
    function allCollateralsTvlUsd() external view returns (uint256);

    /**
     * @dev Returns the total TVL (Total Value Locked) in USD for CygnusDAO.
     * @return The total TVL in USD for CygnusDAO.
     */
    function cygnusTvlUsd() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Admin 👽
     *  @notice Turns off orbiters making them not able for deployment of pools
     *
     *  @param orbiterId The ID of the orbiter pairs we want to switch the status of
     *
     *  @custom:security only-admin
     */
    function switchOrbiterStatus(uint256 orbiterId) external;

    /**
     *  @notice Admin 👽
     *  @notice Initializes both Borrow arms and the collateral arm
     *
     *  @param lpTokenPair The address of the underlying LP Token this pool is for
     *  @param orbiterId The ID of the orbiters we want to deploy to (= dex Id)
     *  @return borrowable The address of the Cygnus borrow contract for this pool
     *  @return collateral The address of the Cygnus collateral contract for both borrow tokens
     *
     *  @custom:security non-reentrant only-admin 👽
     */
    function deployShuttle(address lpTokenPair, uint256 orbiterId) external returns (address borrowable, address collateral);

    /**
     *  @notice Admin 👽
     *  @notice Sets a new pending admin for Cygnus
     *
     *  @param newCygnusAdmin Address of the requested Cygnus admin
     *
     *  @custom:security only-admin
     */
    function setPendingAdmin(address newCygnusAdmin) external;

    /**
     *  @notice Admin 👽
     *  @notice Approves the pending admin and is the new Cygnus admin
     *
     *  @custom:security only-admin
     */
    function setNewCygnusAdmin() external;

    /**
     *  @notice Admin 👽
     *  @notice Sets the address for the future reserves manger if accepted
     *  @param newDaoReserves The address of the requested contract to be the new daoReserves
     *  @custom:security only-admin
     */
    function setPendingDaoReserves(address newDaoReserves) external;

    /**
     *  @notice Admin 👽
     *  @notice Accepts the new implementation contract
     *
     *  @custom:security only-admin
     */
    function setNewDaoReserves() external;

    /**
     *  @notice Admin 👽
     *  @notice Sets the address of the new x1 vault which accumulates rewards over time
     *
     *  @custom:security only-admin
     */
    function setCygnusX1Vault(address newX1Vault) external;
}
