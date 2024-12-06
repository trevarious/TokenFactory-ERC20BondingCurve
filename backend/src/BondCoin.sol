// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title BondCoin
 * @dev A token contract implementing a bonding curve with buy/sell functionality and protocol fees.
 */
contract BondCoin is ERC20, ReentrancyGuard {
    // Maximum supply of the token
    uint256 public constant MAX_SUPPLY = 1_000_000 * 10 ** 18;

    // Initial price for the token
    uint256 public constant INITIAL_PRICE = 0.0001 ether;

    // Maximum price for the token
    uint256 public constant MAX_PRICE = 1 ether;

    // Protocol fee percentage on transactions
    uint256 public constant PROTOCOL_FEE_PERCENT = 5;

    // Maximum percentage of total supply a user can sell at once
    uint256 public constant MAX_SELL_PERCENT = 20;

    // Minimum time between consecutive sales by a user
    uint256 public constant SELL_COOLDOWN = 5 minutes;

    // Address where protocol fees are collected
    address public immutable feeCollector;

    // Total amount of fees collected
    uint256 public totalFeeCollected;

    // Mapping to track the last sell timestamp for each address
    mapping(address => uint256) public lastSellTimestamp;

    // Mapping to track total amount sold by each address
    mapping(address => uint256) public totalSold;

    // Event emitted when tokens are bought
    event TokenBought(address indexed buyer, uint256 amount, uint256 price);

    // Event emitted when tokens are sold
    event TokenSold(address indexed seller, uint256 amount, uint256 price);

    // Event emitted when protocol fees are collected
    event ProtocolFeeCollected(uint256 amount);

    /**
     * @dev Constructor to initialize the contract with creator and fee collector.
     * @param _creator The address of the creator to allocate the initial supply to.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     * @param _feeCollector The address that will collect protocol fees.
     */
    constructor(address _creator, string memory _name, string memory _symbol, address _feeCollector)
        ERC20(_name, _symbol)
    {
        feeCollector = _feeCollector;

        // Initial supply allocation (20% of the max supply)
        uint256 initialSupply = MAX_SUPPLY * 20 / 100;
        _mint(_creator, initialSupply);
    }

    /**
     * @dev Returns the current price of the token based on the remaining supply.
     * @return The current price of the token in wei.
     */
    function getCurrentPrice() public view returns (uint256) {
        uint256 currentSupply = totalSupply();

        // Inverse bonding curve: price increases as supply decreases
        uint256 price = INITIAL_PRICE * MAX_SUPPLY / (currentSupply + 1);

        // Ensure the price does not exceed the maximum allowed price
        return price > MAX_PRICE ? MAX_PRICE : price;
    }

    /**
     * @dev Allows users to buy tokens by sending ETH to the contract.
     * @notice The amount of tokens purchased is based on the current price and the ETH sent.
     * @dev Calls a nonReentrant modifier to prevent re-entrancy attacks.
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
     * @dev Allows users to sell tokens for ETH.
     * @param amount The number of tokens to sell.
     * @notice The maximum sell amount is limited to prevent large market sell-offs.
     * @dev Calls a nonReentrant modifier to prevent re-entrancy attacks.
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
     * @dev Fallback function to allow buying tokens by sending ETH directly to the contract address.
     */
    receive() external payable {
        buy();
    }

    /**
     * @dev Returns the current contract's ETH balance.
     * @return The contract's current ETH balance in wei.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the total amount of protocol fees collected by the contract.
     * @return The total fee amount in wei.
     */
    function getFeeCollected() external view returns (uint256) {
        return totalFeeCollected;
    }
}
