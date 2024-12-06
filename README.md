# BondCoin & TokenFactory

This project includes two main components:  
1. **BondCoin**: An ERC20 token with a bonding curve mechanism, allowing users to buy and sell tokens at dynamically adjusted prices.  
2. **TokenFactory**: A contract for creating new instances of the BondCoin token with custom names and symbols.

## Features

- **BondCoin Token**:  
  - Implements a bonding curve for token pricing based on supply.
  - Users can buy and sell tokens with dynamically changing prices.
  - 5% protocol fee on each buy/sell transaction.
  - Sell limits to prevent large market dumps, with a cooldown period between sales.

- **TokenFactory**:  
  - Allows users to create new `BondCoin` tokens with custom names and symbols.
  - Tracks the creator of each generated `BondCoin` token.

## How It Works

### BondCoin Contract
- **Buy Tokens**: Users can send ETH to the contract to buy tokens. The price per token is determined by the remaining supply using a bonding curve.
- **Sell Tokens**: Users can sell tokens back to the contract for ETH, with limits on how much they can sell at once to avoid market manipulation.
- **Protocol Fees**: A 5% fee is taken on both buys and sells, collected by the designated fee collector.

### TokenFactory Contract
- The `TokenFactory` contract allows users to deploy new `BondCoin` contracts. Each newly created token can have a custom name and symbol.
- The creator of each token is tracked, and they have full control over their created BondCoin contract.

## Events

- `TokenBought`: Emitted when a user buys tokens.
- `TokenSold`: Emitted when a user sells tokens.
- `ProtocolFeeCollected`: Emitted when protocol fees are collected from a transaction.
