// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Buyer} from "../src/21-Shop/Buyer.sol";

interface IShop {
    function buy() external;
    function price() external view returns (uint256);
    function isSold() external view returns (bool);
}

contract TestShop is Test {
    address private constant TARGET_ADDRESS = 0xe305FbB022a127E279d75F2cADd913ff05C1B56D;
    IShop target;
    Buyer buyerContract; 
    address buyer;

    function setUp() public {
        vm.createSelectFork(vm.envString("SEPOLIA_RPC_URL"));

        target = IShop(TARGET_ADDRESS);
        buyer = makeAddr("buyer");
        buyerContract = new Buyer();
    }

    function testShop() public {
        uint256 oldPrice = target.price();

        vm.prank(buyer);
        buyerContract.buy();

        uint256 newPrice = target.price();
        bool isSold = target.isSold();

        assert(newPrice < oldPrice);
        assert(isSold);
    }
    
}