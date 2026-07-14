// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

interface IPuzzleWallet {
    function owner() external view returns (address);
    function maxBalance() external view returns (uint256);
    function whitelisted(address addr) external view returns (bool);
    function balances(address addr) external view returns (uint256);
}

contract TestPuzzleWallet is Test {
    address private constant TARGET_ADDRESS = 0xd9E87c688E041921639eC80cF56FCAaA76a7d2AD;
    IPuzzleWallet target;
    address attacker;

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        target = IPuzzleWallet(TARGET_ADDRESS);
        attacker = vm.addr(vm.envUint("PRIVATE_KEY"));
    }

    function testPuzzleWallet() public {
        address owner = target.owner();
        uint256 maxBalance = target.maxBalance();
        // console2.log("OWNER : ", owner);
        // console2.log("Max Balance: ", maxBalance);
        // console2.log("Contract balance : ", address(target).balance);
        // console2.log(target.whitelisted(owner));
        console2.log(target.balances(owner));
        console2.log(target.balances(TARGET_ADDRESS));
        // console2.log(type(uint256).max - uint256(652733554269361572482625626281549340425241315364));

        bytes32 slot = hex"360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc";

        bytes32 value = vm.load(TARGET_ADDRESS, slot);

        // console2.log(address(uint160(uint256(value))));
        // console2.log(0x2734b204884d11D970D2DbA7a3d82f5A492003f6.balance);

    }

}