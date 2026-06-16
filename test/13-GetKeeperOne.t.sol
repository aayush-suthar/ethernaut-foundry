// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {Attacker} from "../src/13-GateKeeperOne/Attacker.sol";

interface IGatekeeperOne {
    function entrant() external view returns (address);
}

contract TestGatekeeperOne is Test {
    address constant TARGET = 0xfc50E053f9bc7038e42B76ff28aa8F26B9b06063;

    IGatekeeperOne target;
    Attacker attacker;

    function setUp() public {
        vm.createSelectFork(vm.envString("SEPOLIA_RPC_URL"));
        target = IGatekeeperOne(TARGET);
        attacker = new Attacker(TARGET);
    }

    function testExploit() public {
        vm.startPrank(msg.sender, msg.sender);

        bool success = attacker.attack();
        assertTrue(success);

        assertEq(target.entrant(), msg.sender);

        vm.stopPrank();
    }
}