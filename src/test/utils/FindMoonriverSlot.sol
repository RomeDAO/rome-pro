// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "../../../lib/ds-test/src/test.sol";
import "./Vm.sol";

interface IERC20 {
    function balanceOf(address acount) external returns (uint256);
}

contract MoonriverTestSetBalance is DSTest {
    function test_HevmStoreHND() public {
        Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        address TOKEN = 0x10010078a54396F62c96dF8532dc2B4847d47ED3;
        IERC20 token = IERC20(TOKEN);

        uint256 index;
        for (uint256 i = 0; i < 100; i++) {
            vm.store(
                TOKEN,
                keccak256(
                    abi.encode(
                        0x3a3eE61F7c6e1994a2001762250A5E17B2061b6d,
                        uint256(i)
                    )
                ),
                bytes32(uint256(10 * 1e6))
            );
            uint256 balance = token.balanceOf(
                0x3a3eE61F7c6e1994a2001762250A5E17B2061b6d
            );
            if (balance == 10 * 1e6) {
                index = i;
                break;
            }
        }

        assertEq(2, index);
    }
}
