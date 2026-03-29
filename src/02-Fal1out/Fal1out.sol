/********************************************
 * You will beat this level if
 * 1. you claim ownership of the contract
 * https://ethernaut.openzeppelin.com/
********************************************/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFallout {
    // We only define the functions we actually need to interact with
    function Fal1out() external payable;
    function owner() external view returns (address);
}