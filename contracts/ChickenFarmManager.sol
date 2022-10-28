// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IBorrowerOperations.sol";

/** TODOS
 *  1. open, close and controll the trove
 */

contract ChickenFarmManager {
    IBorrowerOperations private borrowerOperator;

    constructor(address _borrowerOperaterAddress) {
        borrowerOperator = IBorrowerOperations(_borrowerOperaterAddress);
    }

    function openTrove(
        uint256 _maxFee,
        uint256 _LUSDAmount,
        address _upperHint,
        address _lowerHint
    ) external {
        borrowerOperator.openTrove(
            _maxFee,
            _LUSDAmount,
            _upperHint,
            _lowerHint
        );
    }

    function closeTrove() external {}
}
