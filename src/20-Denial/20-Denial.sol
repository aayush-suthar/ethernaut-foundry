// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import {console2} from "forge-std/console2.sol";

// contract Denial {
//     address public partner; // withdrawal partner - pay the gas, split the withdraw
//     address public constant owner = address(0xA9E);
//     uint256 timeLastWithdrawn;
//     mapping(address => uint256) withdrawPartnerBalances; // keep track of partners balances

//     function setWithdrawPartner(address _partner) public {
//         partner = _partner;
//     }

//     // withdraw 1% to recipient and 1% to owner
//     function withdraw() public {
//         uint256 start1 = gasleft();
//         uint256 amountToSend = address(this).balance / 100;
//         uint256 end1 = gasleft();
        
//         // perform a call without checking return
//         // The recipient can revert, the owner will still get their share

//         partner.call{value: amountToSend}("");
        
//         uint256 start3 = gasleft();
//         payable(owner).transfer(amountToSend);
//         // keep track of last withdrawal time
//         timeLastWithdrawn = block.timestamp;
//         withdrawPartnerBalances[partner] += amountToSend;
//         uint256 end3 = gasleft();
        
//         console2.log("Gas 1: ", start1 - end1);
//         console2.log("Gas 3: ", start3 - end3);
//     }

//     // allow deposit of funds
//     receive() external payable {}

//     // convenience function
//     function contractBalance() public view returns (uint256) {
//         return address(this).balance;
//     }
// }