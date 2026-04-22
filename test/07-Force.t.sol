// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Attacker} from "../src/07-Force/Attacker.sol";

interface IForce {}

contract TestForce is Test {
    address constant public TARGET_ADDRESS = 0xa1f46A3b753644718d6Cddd710f004a32fD41a27;
    address constant public DEPLOYED_ATTACKER_ADDRESS = 0x2525A0742103bc2E356B5B2e5483f176CfBD91EC;
    address attacker;
    IForce target;
    Attacker deployedAttacker;
    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);
        attacker = makeAddr("attacker");
        deal(attacker, 1 wei);
        target = IForce(TARGET_ADDRESS);
        deployedAttacker = Attacker(payable(DEPLOYED_ATTACKER_ADDRESS));
    }

    function testForce() public {
        uint256 startingBalance = address(target).balance;
        
        vm.startPrank(attacker);
        address(deployedAttacker).call{value: 1 wei}("");
        deployedAttacker.attack();
        vm.stopPrank();

        uint256 endingBalance = address(target).balance;

        assertEq(endingBalance - startingBalance , 1);
    }

}