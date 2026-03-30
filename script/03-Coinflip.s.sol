// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

interface Attacker{
    function attacker() external;
}

contract DeployCoinflip is Script {
    address constant private TARGET_ADDRESS = 0x333b591DEDDb356407bc992fe64f474c21b25DC0;
    Attacker attacker = Attacker(0x6DCaeDfDbF1a516FBB1b274C207c5AE3D640a173);

    function run() public {
        uint256 private_key = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(private_key);
        attacker.attacker();
        vm.stopBroadcast();
    }
}
