// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.17;

interface IAlgebraPool {
    function globalState() external view returns (uint160, int24, uint16, uint16, uint8, uint8, bool);
}
