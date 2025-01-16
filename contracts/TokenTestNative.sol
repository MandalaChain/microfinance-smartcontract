// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestToken is ERC20, Ownable {
    constructor() ERC20("Test Token Native", "TTN") Ownable(msg.sender) {
        // Mint initial supply to the deployer's address
        _mint(msg.sender, 1000000 * (10 ** decimals()));
    }

    // Function to mint new tokens, restricted to the owner
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Function to burn tokens, restricted to the owner
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}
