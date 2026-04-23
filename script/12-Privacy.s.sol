// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Attacker} from "../src/12-Privacy/Attacker.sol";

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
    address constant private DEPLOYED_ATTACKER_ADDRESS = 0x0cA8064673B9d1803191ed676f5e7BB9cF83042F;
    IAttacker attacker = IAttacker(DEPLOYED_ATTACKER_ADDRESS);
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        attacker.attack();
        vm.stopBroadcast();
    }
}
