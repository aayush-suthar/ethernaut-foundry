/********************************************
 * You will beat this level if
 * 1.  You claim ownership of the contract.
 * https://ethernaut.openzeppelin.com/
********************************************/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}