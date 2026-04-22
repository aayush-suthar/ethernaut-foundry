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

## 06 - Delegation
**Difficulty:** 2/5  
**Vulnerability:** Execution Context Hijacking / Unsafe `delegatecall`

### Analysis
The `delegatecall` opcode is designed to dynamically execute the logic of a target contract while preserving the storage, `msg.sender`, and `msg.value` context of the calling contract. The target `Delegation` contract acts as a primitive proxy, implementing a `fallback()` function that blindly forwards all incoming `msg.data` to the `Delegate` contract. Because the Delegate contract contains a `pwn()` function that explicitly modifies the owner state variable (located at Storage Slot 0), an attacker can leverage the `delegatecall` to weaponize this logic and overwrite the proxy's internal state.

### Exploit Path
1. **The Payload:** Construct the raw 4-byte function selector for the target logic: `abi.encodeWithSignature("pwn()")`.
2. **The Routing:** Send a low-level transaction containing this specific EVM bytecode directly to the `Delegation` proxy contract.
3. **The State Overwrite:** Because `pwn()` does not exist in the proxy's ABI, the EVM routes the transaction to the `fallback()` function. The proxy executes `delegatecall`, reading the logic from `Delegate`, but applying the state change (`owner = msg.sender`) directly to its own Storage Slot 0, permanently granting ownership to the attacker.

### Execution
1. Execute the payload and claim ownership
```bash
forge script script/06-Delegation.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
```

## 07 - Force
**Difficulty:** 3/5  
**Vulnerability:** Strict Balance Invariant Break / Forced Ether Delivery (`SELFDESTRUCT`)

### Analysis
The target `Force` contract is completely empty. It does not implement a `receive()` or a `payable fallback()` function, meaning the EVM will automatically revert any standard transaction that attempts to send Ether to it. However, the EVM contains specific protocol-level exceptions that bypass the standard execution environment. The `selfdestruct` opcode destroys the calling contract and forcefully teleports its remaining Ether balance to a target address. Because this is a state transition at the protocol level, no code is executed in the target contract, meaning it physically cannot revert the incoming Ether.

### Exploit Path
1. **The Architecture:** Deploy an intermediate malicious `Attacker` contract that contains a `payable fallback` function (to receive funds) and an `attack()` function that executes the `selfdestruct` opcode.
2. **The Funding:** Send a low-level transaction with a small value (1 wei) to fund the deployed `Attacker` contract.
3. **The Detonation:** Trigger the `attack()` function. The EVM destroys the `Attacker` contract and forcefully pushes the 1 wei into the `Force` contract, completely bypassing its lack of payable functions and forcibly increasing its balance.

### Execution
1. Deploy the intermediate kamikaze contract:
```bash
forge script script/07-Force.s.sol:DeployAttacker --rpc-url $SEPOLIA_RPC_URL --broadcast
```
2. Fund the attacker and trigger the detonation:
```bash
forge script script/07-Force.s.sol:Attack --rpc-url $SEPOLIA_RPC_URL --broadcast
```

## 08 - Vault
**Difficulty:** 2/5  
**Vulnerability:** Insecure On-Chain Data / State Variable Visibility

### Analysis
The target `Vault` contract attempts to secure its unlock mechanism by storing the password in a `private` state variable. This is a fundamental architectural misunderstanding of blockchain consensus. In Solidity, the `private` keyword is strictly a compiler-level safeguard—it only prevents other smart contracts from calling and reading the variable during an EVM execution frame. It does absolutely nothing to encrypt or hide the data on the network. Because every Ethereum node must maintain the global state tree to reach consensus, all storage slots of all deployed contracts are completely public and can be queried directly via the RPC endpoint (`eth_getStorageAt`), completely bypassing EVM access controls.

### Exploit Path
1. **Slot Calculation:** EVM storage slots are 32 bytes each. The contract defines `bool public locked` first. A boolean requires 1 byte, but because the next variable is a `bytes32` (which requires a full 32-byte slot), the EVM cannot pack them together. Therefore, `locked` occupies Storage Slot 0, and the `private password` occupies Storage Slot 1.
2. **The Extraction:** Query the blockchain directly to read the raw hexadecimal data stored inside Storage Slot 1 of the target contract. In Foundry, this is done using the `vm.load()` cheatcode or the `cast storage` terminal command.
3. **The Unlock:** Pass the extracted 32-byte hexadecimal password back into the target contract's public `unlock(bytes32)` function to flip the boolean and permanently unlock the vault.

### Execution
1. Execute the payload to extract the private storage and unlock the vault:
```bash
forge script script/08-Vault.s.sol:DeployVault --rpc-url $SEPOLIA_RPC_URL --broadcast
```