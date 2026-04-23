// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Attacker} from "../src/12-Privacy/Attacker.sol";

interface IPrivacy {
    function unlock(bytes16 _key) external;
    function locked() external view returns(bool);
} 

contract TestPrivacy is Test {
    address constant private TARGET_ADDRESS = 0xa43b88A59b3e289CfCb5954D25409c17F2F6ff3c;
    IPrivacy target;
    Attacker attacker;

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        target = IPrivacy(TARGET_ADDRESS);
        attacker = new Attacker();
    }

    function testPrivacy() public {
        attacker.attack();

        assertEq(target.locked(), false);
    }

}




