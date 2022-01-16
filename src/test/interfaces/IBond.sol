// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.5;

interface IBond {

    function deposit(uint _amount, uint _maxPrice, address _depositor) external returns (uint);

    function initializeBond( 
        uint _controlVariable, 
        uint _vestingTerm,
        uint _minimumPrice,
        uint _maxPayout,
        uint _maxDebt,
        uint _initialDebt
    ) external;

    enum PARAMETER { VESTING, PAYOUT, DEBT }
    function setBondTerms ( PARAMETER _parameter, uint _input ) external;
}
