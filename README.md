# Ethernaut Solutions - Foundry

Professional security research and proof-of-concepts for OpenZeppelin's Ethernaut challenges.

## 01 - Fallback
**Difficulty:** 1/5  
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
```

## 02 - Fallout
**Difficulty:** 1/5  
**Vulnerability:** Insecure Initialization / Constructor Naming Typo

### Analysis
In Solidity versions prior to `0.4.22`, a constructor was defined as a function sharing the exact name of the contract. The developer intended to restrict initialization upon deployment but introduced a typographical error (`Fal1out` instead of `Fallout`). Consequently, the EVM compiled this intended constructor as a standard, state-mutating `public payable` function, leaving the initialization logic fully exposed.

### Exploit Path
1. Call the misnamed `Fal1out()` function with a 0 value payload.
2. The function executes `owner = msg.sender` without any access control checks, instantly granting absolute ownership to the caller.

### Execution
```bash
forge script script/02-Fallout.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
```

## 03 - Coin Flip
**Difficulty:** 2/5  
**Vulnerability:** Insecure Randomness / Deterministic State Manipulation

### Analysis
The target contract attempts to simulate a random coin flip by using the `blockhash` of the previous block divided by a static `FACTOR`. In the Ethereum Virtual Machine (EVM), true randomness cannot be natively generated because all state transitions must be completely deterministic for network nodes to reach consensus. Because block variables (like `block.number` and `blockhash`) are globally visible, they are entirely predictable to other smart contracts executing in the exact same block.

### Exploit Path
1. **The Architecture:** Due to the EVM's atomic execution, an external script cannot reliably win because of network latency and mempool dynamics (a Race Condition). Furthermore, the target contract implements a `lastHash` check to prevent a single transaction from looping the attack in the same block.
2. **The Payload:** Deployed an autonomous `Attacker.sol` smart contract to the Sepolia network. 
3. **Atomic Execution:** Triggered the `Attacker` contract via an off-chain Foundry script 10 separate times, waiting for block finality between each call. The `Attacker` contract reads the exact same `block.number` and calculates the exact same `blockhash` as the target, natively predicting the flip with 100% accuracy in real-time.

### Execution
1. Deploy the payload:
`forge create src/03-Coinflip/Attacker.sol:Attacker --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --legacy --broadcast --constructor-args <TARGET_ADDRESS>`
2. Arm the Foundry script (`script/03-Coinflip.s.sol`) with the deployed `Attacker` address.
3. Execute the delivery shell script to bypass the loop trap:
```bash
for i in {1..10}; do
  forge script script/03-Coinflip.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
  sleep 15
done
```

## 04 - Telephone
**Difficulty:** 1/5  
**Vulnerability:** Execution Context Confusion / Insecure Access Control (`tx.origin`)

### Analysis
The EVM tracks two distinct sender variables within its execution context: `msg.sender` (the immediate caller, which can be an Externally Owned Account or a smart contract) and `tx.origin` (the original EOA that signed the entire transaction chain). The target contract conditionally grants ownership by verifying `if (tx.origin != msg.sender)`. Relying on `tx.origin` for authorization is a severe EVM anti-pattern. It leaves protocols highly vulnerable to phishing attacks, as an intermediate malicious contract can forward a call on behalf of a user, completely spoofing the expected execution context.

### Exploit Path
1. **The Architecture:** Deployed an intermediary `Attacker.sol` smart contract.
2. **The Context Shift:** Triggered the `attack()` function on the deployed `Attacker` contract from the local wallet (EOA). The `Attacker` contract subsequently makes an external call to the target's `changeOwner()` function.
3. **The Payload Bypass:** When the `Telephone` contract evaluates the execution state, `msg.sender` resolves to the address of the `Attacker` contract, while `tx.origin` remains the address of the original EOA wallet. Because `tx.origin != msg.sender` evaluates to `true`, the authorization check is bypassed, and absolute ownership is granted to the EOA address passed in the calldata.

### Execution
1. Deploy the intermediary attacker contract
```bash
forge script script/04-Telephone.s.sol:DeployAttacker --rpc-url $SEPOLIA_RPC_URL --broadcast
```

2. Execute the payload and claim ownership
```bash
forge script script/04-Telephone.s.sol:Attack --rpc-url $SEPOLIA_RPC_URL --broadcast
```