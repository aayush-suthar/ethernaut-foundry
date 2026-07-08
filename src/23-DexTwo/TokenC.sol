// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenC is ERC20 {
    constructor() ERC20("Token C", "C") {}

    function mint(address user, uint256 amount) public {
        _mint(user, amount);
    }
    function burn(address user, uint256 amount) public {
        _burn(user, amount);
    }
}