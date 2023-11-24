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
    
        CYGNUS HARVESTER - `COMP HARVESTER`                                                           
    ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  */
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusHarvester, CygnusHarvester} from "./CygnusHarvester.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";

// Libraries
import {SafeTransferLib} from "./libraries/SafeTransferLib.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

// Interfaces
import {IHangar18} from "./interfaces/core/IHangar18.sol";
import {ICygnusTerminal} from "./interfaces/core/ICygnusTerminal.sol";

/// @title CompoundHarvester
/// @author CygnusDAO
/// @notice CompoundHarvester fo quickswap pools
contract CompoundHarvester is CygnusHarvester {
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
    string public override name = "Cygnus: COMP Harvester";

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

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

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

        /// Revert if no liquidity to reinvest
        if (liquidity == 0) revert("Insufficient want");

        // ─────────────────────── 5. Reinvest Rewards
        // Reinvest rewards in core, minting 0 shares and increasing totalBalance.
        ICygnusTerminal(harvester.terminal).reinvestRewards_y7b(liquidity);
    }
}
