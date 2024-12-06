// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title BondCoin
 * @dev This contract represents a speculative ERC20 token with dynamic pricing,
 * buy/sell functionality, and a protocol fee mechanism. The contract implements
 * anti-bot measures and market dynamics through a cooldown and max sell percentage.
 */
contract BondCoin is ERC20, ReentrancyGuard {
    /**
     * @dev The maximum supply of ShillCoin tokens.
     */
    uint256 public constant MAX_SUPPLY = 1_000_000 * 10 ** 18;

    /**
     * @dev The initial price of ShillCoin (in wei per token).
     */
    uint256 public constant INITIAL_PRICE = 0.0001 ether;

    /**
     * @dev The maximum price of ShillCoin (in wei per token).
     */
    uint256 public constant MAX_PRICE = 1 ether;

    /**
     * @dev The protocol fee percentage on every buy and sell transaction.
     */
    uint256 public constant PROTOCOL_FEE_PERCENT = 5;

    /**
     * @dev The maximum percentage of the current total supply that can be sold in one transaction.
     */
    uint256 public constant MAX_SELL_PERCENT = 20;

    /**
     * @dev The cooldown time between consecutive sell actions for an address.
     */
    uint256 public constant SELL_COOLDOWN = 5 minutes;

    /**
     * @dev Address of the fee collector where the protocol fee is sent.
     */
    address public immutable feeCollector;

    /**
     * @dev Total fee collected by the contract.
     */
    uint256 public totalFeeCollected;

    /**
     * @dev Tracks the last sell timestamp for each address.
     */
    mapping(address => uint256) public lastSellTimestamp;

    /**
     * @dev Tracks the total amount of tokens sold by each address.
     */
    mapping(address => uint256) public totalSold;

    /**
     * @dev Emitted when tokens are bought.
     * @param buyer Address of the buyer.
     * @param amount Amount of tokens bought.
     * @param price Price per token at the time of purchase.
     */
    event TokenBought(address indexed buyer, uint256 amount, uint256 price);

    /**
     * @dev Emitted when tokens are sold.
     * @param seller Address of the seller.
     * @param amount Amount of tokens sold.
     * @param price Price per token at the time of sale.
     */
    event TokenSold(address indexed seller, uint256 amount, uint256 price);

    /**
     * @dev Emitted when the protocol fee is collected.
     * @param amount Amount of fee collected.
     */
    event ProtocolFeeCollected(uint256 amount);

    /**
     * @dev Constructor that initializes the token name, symbol, and fee collector.
     * @param _creator Address of the creator (initial token distribution).
     * @param _name Name of the token.
     * @param _symbol Symbol of the token.
     * @param _feeCollector Address where the protocol fee will be collected.
     */
    constructor(address _creator, string memory _name, string memory _symbol, address _feeCollector)
        ERC20(_name, _symbol)
    {
        feeCollector = _feeCollector;

        // Initial supply allocation (20%)
        uint256 initialSupply = MAX_SUPPLY * 20 / 100;
        _mint(_creator, initialSupply);
    }

    /**
     * @dev Returns the current price of the token based on the dynamic pricing mechanism.
     * @return The current price of the token in wei.
     */
    function getCurrentPrice() public view returns (uint256) {
        uint256 currentSupply = totalSupply();

        // Inverse bonding curve: price increases as supply decreases
        uint256 price = INITIAL_PRICE * MAX_SUPPLY / (currentSupply + 1);

        return price > MAX_PRICE ? MAX_PRICE : price;
    }

    /**
     * @dev Allows the user to buy tokens with ETH.
     * @dev The price per token is determined by the dynamic pricing mechanism.
     * @dev A protocol fee is deducted from the purchase amount and sent to the feeCollector.
     * @dev The maximum supply cannot be exceeded.
     * @dev Emits a TokenBought event upon success.
     */
    function buy() public payable nonReentrant {
        require(msg.value > 0, "Must send ETH");
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");

        uint256 currentPrice = getCurrentPrice();
        uint256 tokenAmount = (msg.value * 10 ** 18) / currentPrice;

        // Ensure we don't exceed max supply
        if (totalSupply() + tokenAmount > MAX_SUPPLY) {
            tokenAmount = MAX_SUPPLY - totalSupply();
        }

        // Calculate protocol fee
        uint256 protocolFee = msg.value * PROTOCOL_FEE_PERCENT / 100;
        totalFeeCollected += protocolFee;
        payable(feeCollector).transfer(protocolFee);

        // Mint tokens to buyer
        _mint(msg.sender, tokenAmount);

        emit TokenBought(msg.sender, tokenAmount, currentPrice);
    }

    /**
     * @dev Allows the user to sell tokens for ETH.
     * @dev The amount of tokens that can be sold is limited to a percentage of the total supply.
     * @dev A protocol fee is deducted from the sale and sent to the feeCollector.
     * @dev Tokens are burned upon successful sale.
     * @dev A cooldown is enforced between consecutive sell actions.
     * @dev Emits a TokenSold event upon success.
     * @param amount Amount of tokens to sell.
     */
    function sell(uint256 amount) public nonReentrant {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(block.timestamp >= lastSellTimestamp[msg.sender] + SELL_COOLDOWN, "Sell cooldown active");

        uint256 currentSupply = totalSupply();

        // Limit sell amount to prevent massive dumps
        uint256 maxSellAmount = currentSupply * MAX_SELL_PERCENT / 100;
        require(amount <= maxSellAmount, "Exceeds max sell limit");

        uint256 currentPrice = getCurrentPrice();
        uint256 sellValue = amount * currentPrice / 10 ** 18;

        // Calculate protocol fee
        uint256 protocolFee = sellValue * PROTOCOL_FEE_PERCENT / 100;
        uint256 sellerAmount = sellValue - protocolFee;

        // Burn tokens
        _burn(msg.sender, amount);

        // Transfer ETH to seller
        payable(msg.sender).transfer(sellerAmount);

        // Collect protocol fee
        totalFeeCollected += protocolFee;
        payable(feeCollector).transfer(protocolFee);

        // Update sell tracking
        lastSellTimestamp[msg.sender] = block.timestamp;
        totalSold[msg.sender] += amount;

        emit TokenSold(msg.sender, amount, currentPrice);
    }

    /**
     * @dev Fallback function that allows users to buy tokens by sending ETH directly to the contract.
     * @dev This function calls the `buy` method internally.
     */
    receive() external payable {
        buy();
    }

    /**
     * @dev Returns the current balance of ETH held by the contract.
     * @return The current balance of the contract in wei.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the total amount of protocol fees collected by the contract.
     * @return The total amount of protocol fees in wei.
     */
    function getFeeCollected() external view returns (uint256) {
        return totalFeeCollected;
    }
}
