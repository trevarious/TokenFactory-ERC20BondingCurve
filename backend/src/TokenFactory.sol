// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BondCoin} from "./BondCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TokenFactory is ReentrancyGuard {
    // Custom error for owner-only function access
    error Shillers__OnlyOwnerCanCallThis();

    // State variables
    address public owner; // Contract owner
    address[] public coins; // List of created coins (BondCoins)
    mapping(address => address) public coinsCreator; // Mapping from coin address to its creator

    modifier ownerOnly(address sender) {
        require(sender == owner, Shillers__OnlyOwnerCanCallThis());
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createCoin(string memory name, string memory symbol) external nonReentrant returns (address) {
        BondCoin bondCoin = new BondCoin(msg.sender, name, symbol, address(this));
        coinsCreator[address(bondCoin)] = msg.sender;
        coins.push(address(bondCoin));
        return address(bondCoin);
    }

    function getCreatorOfCoin(address coin) public view returns (address) {
        return coinsCreator[coin];
    }

    function getCoins() public view returns (address[] memory) {
        return coins;
    }

    receive() external payable {}
}
