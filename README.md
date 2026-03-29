# Ethernaut Solutions - Foundry

Professional security research and proof-of-concepts for OpenZeppelin's Ethernaut challenges.

## 01 - Fallback
**Difficulty:** 1/10  
**Vulnerability:** Broken Access Control / Insecure Logic in `receive()`

### Analysis
The contract allows any user to become the `owner` by satisfying two conditions in the `receive()` function:
1. `msg.value > 0`
2. `contributions[msg.sender] > 0`

### Exploit Path
1. Call `contribute()` with a small amount of ETH (< 0.001 ETH) to satisfy the second condition.
2. Send a low-level transaction with 0 data and 1 wei to trigger the `receive()` function.
3. Call `withdraw()` as the new owner to drain the contract.

### Execution
```bash
forge script script/01-Fallback.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast