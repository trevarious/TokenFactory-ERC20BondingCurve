# ShillersNoVRF & BondCoin

This repository contains two Solidity smart contracts: **ShillersNoVRF** and **BondCoin**. These contracts allow users to create and manage speculative tokens with dynamic pricing mechanisms, anti-bot features, and protocol fee collection.

## Overview

The two contracts work together to enable the creation of user-generated tokens (PumpCoins) with dynamic pricing and associated buying/selling functionality. The **ShillersNoVRF** contract allows the creation of new tokens, while **BondCoin** defines the logic for dynamic pricing, cooldowns, and protocol fees.

### Contracts:

1. **ShillersNoVRF**: 
   - A contract for creating unique tokens (PumpCoins) with dynamic scaling factors.
   - Allows the owner to track and manage coins.
   
2. **BondCoin**: 
   - A speculative ERC20 token with a dynamic pricing mechanism, market dynamics, and anti-bot measures.
   - Includes functionality for buying, selling, and collecting protocol fees.

---

## ShillersNoVRF Contract

### Description

The **ShillersNoVRF** contract is responsible for creating speculative tokens (PumpCoins) by allowing users to trigger a random scaler and exponent. It keeps track of all created tokens and their respective creators.

### Key Features

- **Create PumpCoins**: Users can create a custom token (PumpCoin) by providing a name and symbol.
- **Tracking Creators**: The contract maps each token to its creator.
- **Only Owner**: Certain administrative actions can only be performed by the contract owner.

### Functions

- **`createCoin(string memory name, string memory symbol)`**:
  - Creates a new **PumpCoin** (BondCoin) for the caller with the given name and symbol.
  - Emits a `TokenCreated` event when successful.
  
- **`getCreatorOfCoin(address coin)`**:
  - Retrieves the creator of a particular coin by its address.

- **`getCoins()`**:
  - Returns an array of all created coins' addresses.

### Example

```solidity
ShillersNoVRF shillersContract = new ShillersNoVRF();
address newCoinAddress = shillersContract.createCoin("MyToken", "MTK");
