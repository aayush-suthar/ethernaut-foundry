// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Attacker} from "../src/11-Elevator/Attacker.sol";


interface IElevator {
    function goTo(uint256 _floor) external;
    function top() external view returns (bool);
}

contract TestElevator is Test{
    address constant private TARGET_ADDRESS = 0xda9A7754817317Ca8D1fd1d6A6F496Bd919b8C24;
    IElevator target;
    Attacker attacker;

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);
        target = IElevator(TARGET_ADDRESS);
        attacker = new Attacker();
    }

    function testElevator() public {
        attacker.attack();
        assertEq(target.top() , true);
    }

}
