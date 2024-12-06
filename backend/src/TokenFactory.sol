// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BondCoin} from "./BondCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ShillersNoVRF
 * @dev This contract allows users to activate a random scaler and exponent,
 * and then create a new token (PumpCoin) using those values. It simulates randomness
 * for token creation and provides functionality for managing created tokens.
 */
contract ShillersNoVRF is ReentrancyGuard {
    // Custom error for restricted access (only owner can call certain functions)
    error Shillers__OnlyOwnerCanCallThis();

    // State variables
    address public owner; // Owner address
    address[] public coins; // Array of all created coins (PumpCoins)
    mapping(address => address) public coinsCreator; // Track creator of each coin

    /**
     * @dev Restricts function execution to the contract owner.
     * @param sender The address attempting to call the function.
     */
    modifier ownerOnly(address sender) {
        require(sender == owner, Shillers__OnlyOwnerCanCallThis());
        _;
    }
    /**
     * @dev Constructor to initialize the contract with the deployer's address as the owner.
     */

    constructor() {
        owner = msg.sender;
    }
    /**
     * @dev Creates a new PumpCoin (ShillCoin) token for the caller.
     * @notice The caller must have activated their scaler before they can create a coin.
     * @param name The name of the new PumpCoin.
     * @param symbol The symbol of the new PumpCoin.
     * @return address The address of the newly created PumpCoin contract.
     */

    function createCoin(string memory name, string memory symbol) external nonReentrant returns (address) {
        // Create a new BondCoin with the user's scaler and exponent
        BondCoin pumpCoin = new BondCoin(msg.sender, name, symbol, address(this));

        // Track the creator and store the coin address
        coinsCreator[address(pumpCoin)] = msg.sender;
        coins.push(address(pumpCoin));
        return address(pumpCoin);
    }

    /**
     * @dev Retrieves the creator address of a particular coin.
     * @param coin The address of the coin (PumpCoin).
     * @return The address of the coin's creator.
     */
    function getCreatorOfCoin(address coin) public view returns (address) {
        return coinsCreator[coin];
    }

    /**
     * @dev Retrieves all coins created by the contract.
     * @return An array of addresses of all created coins.
     */
    function getCoins() public view returns (address[] memory) {
        return coins;
    }

    receive() external payable {}
}
