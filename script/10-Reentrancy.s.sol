// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Attacker} from "../src/10-Re-entrancy/Attacker.sol";

contract DeployAttacker is Script{
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        Attacker attacker = new Attacker();
        vm.stopBroadcast();
    }
}

interface IAttacker{
    function deposit() external payable;
}

contract DeployAttack is Script{
    address constant private DEPLOYED_ATTACKER_ADDRESS = 0xAb42f8675D2ab7D311edf5ce7C4a5aA342024d71;
    uint256 constant private BALANCE = 0.0005 ether;
    IAttacker attacker = IAttacker(DEPLOYED_ATTACKER_ADDRESS);
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        attacker.deposit{value: BALANCE}();
        vm.stopBroadcast();
    }
}

