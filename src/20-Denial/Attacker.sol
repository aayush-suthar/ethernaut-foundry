// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Attacker{
    receive() payable external {
        while(true){
            /* Let's 🔥 gas */
        }
    }
}