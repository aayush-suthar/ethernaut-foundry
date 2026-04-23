// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Attacker} from "../src/11-Elevator/Attacker.sol";

contract DeployAttacker is Script{
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        Attacker attacker = new Attacker();
        vm.stopBroadcast();
    }
}

interface IAttacker{
    function attack() external;
}

contract DeployAttack is Script{
    address constant private DEPLOYED_ATTACKER_ADDRESS = 0x473e2e6F3B8B5b6274bEED041A0541A339dB7D9A;
    IAttacker attacker = IAttacker(DEPLOYED_ATTACKER_ADDRESS);
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        attacker.attack();
        vm.stopBroadcast();
    }
}
