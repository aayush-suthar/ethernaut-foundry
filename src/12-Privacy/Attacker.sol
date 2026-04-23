// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IPrivacy {
    function unlock(bytes16 _key) external;
    function locked() external view returns(bool);
} 

contract Attacker {
    address constant private TARGET_ADDRESS = 0xa43b88A59b3e289CfCb5954D25409c17F2F6ff3c;
    IPrivacy target = IPrivacy(TARGET_ADDRESS);
    
    // cast storage 0xa43b88A59b3e289CfCb5954D25409c17F2F6ff3c 5 --rpc-url $SEPOLIA_RPC_URL
    bytes16 key = bytes16(bytes32(0x18c773c3034e1d06df1f2cb27c119cba91566c6386144385e731e4b68972614a));

    function attack() public {
        target.unlock(key);
    }

}