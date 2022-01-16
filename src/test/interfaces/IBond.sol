// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.5;

interface IBond {

    function deposit(uint _amount, uint _maxPrice, address _depositor) external returns (uint);

}
