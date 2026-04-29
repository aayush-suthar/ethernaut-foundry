// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {Attacker} from "../src/13-GateKeeperOne/Attacker.sol";

contract DeployAndAttack is Script {
    address constant TARGET = 0xfc50E053f9bc7038e42B76ff28aa8F26B9b06063;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        Attacker attacker = new Attacker(TARGET);
        attacker.attack();

        vm.stopBroadcast();
    }
}