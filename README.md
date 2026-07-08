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

## 09 - King
**Difficulty:** 3/5  
**Vulnerability:** Denial of Service (DoS) / Unhandled External Call Revert

### Analysis
The target `King` contract utilizes a dangerous "push" payment architecture. When a user sends an amount of Ether greater than or equal to the current `prize`, the contract attempts to refund the previous king by executing an external Ether transfer. The critical flaw is that the state transition (updating the `king` address) strictly depends on the success of this external transfer. If the previous king is a smart contract designed to refuse Ether, the refund transfer will revert, causing the entire execution frame to revert. This permanently bricks the protocol, preventing anyone from ever interacting with it again. This vulnerability highlights exactly why the "Pull over Push" withdrawal pattern is a mandatory standard in Web3 security.

### Exploit Path
1. **The Architecture:** Deploy a malicious `Attacker` contract that explicitly rejects incoming Ether. This is achieved by defining a `fallback()` function that contains a strict `revert()` statement.
2. **The Takeover:** Query the target contract for the current `prize`. Trigger the `Attacker` contract's `attack()` function to send a payload to the target with a `msg.value` slightly larger than the current prize. The `Attacker` contract is now registered in the target's state as the new King.
3. **The Lockout:** When the Ethernaut factory (or any future player) attempts to send Ether to reclaim the kingship, the target contract will attempt to refund the `Attacker`. The `Attacker`'s `fallback` triggers the `Attacker__AlwaysRevert` error, immediately halting and reverting the transaction. The target contract is permanently locked in a Denial of Service state.

### Execution
1. Deploy the malicious `Attacker` contract:
```bash
forge script script/09-King.s.sol:DeployAttacker --rpc-url $SEPOLIA_RPC_URL --broadcast
```
2. Execute the payload to claim the kingship and permanently brick the target:
```bash
forge script script/09-King.s.sol:DeployAttack --rpc-url $SEPOLIA_RPC_URL --broadcast
```

## 10 - Re-entrancy
**Difficulty:** 3/5  
**Vulnerability:** Reentrancy / Checks-Effects-Interactions (CEI) Violation

### Analysis
The target `Reentrance` contract suffers from a classic state-synchronization flaw. When processing a withdrawal, the contract executes a low-level external call (`msg.sender.call{value: _amount}("")`) to send Ether **before** updating the user's balance in its internal accounting state. In the EVM, an external call hands over the execution control flow to the receiving address. If the receiver is a malicious smart contract, it can leverage its `fallback` or `receive` function to recursively call the target's `withdraw()` function. Because the target's internal state has not yet been updated, it continues to believe the attacker has a valid balance, dispensing Ether in an infinite loop until its entire balance is drained. This is a critical violation of the Checks-Effects-Interactions pattern.

### Exploit Path
1. **The Architecture:** Deploy a malicious `Attacker` contract. This contract must contain a `fallback()` function containing the recursive payload: a conditional check (`if address(target).balance > 0`) followed by a subsequent call to `target.withdraw()`.
2. **The Primer:** Execute the `deposit()` function on the `Attacker` contract. This sends a small primer amount (`0.0005 ether`) to the target's `donate()` function, officially registering a balance for the `Attacker` in the target's internal mapping.
3. **The Loop:** In the exact same transaction, the `Attacker` calls `target.withdraw()` for the initial primer amount. The target sends the Ether, triggering the `Attacker`'s `fallback()`. The `fallback()` intercepts the execution flow and immediately calls `target.withdraw()` again. This cycle repeats, draining the target's complete ETH balance before the initial execution frame can ever resolve and update the balances.

### Execution
1. Deploy the malicious `Attacker` contract:
```bash
forge script script/10-Reentrancy.s.sol:DeployAttacker --rpc-url $SEPOLIA_RPC_URL --broadcast
```
2. Execute the payload to prime the mapping and drain the target:
```bash
forge script script/10-Reentrancy.s.sol:DeployAttack --rpc-url $SEPOLIA_RPC_URL --broadcast
```

## 11 - Elevator
**Difficulty:** 2/5  
**Vulnerability:** Interface Manipulation / Unsafe External Call Trust

### Analysis
The target `Elevator` contract relies on an external interface (`Building`) to determine if a requested floor is the top floor. The critical architectural flaw is that the `goTo()` function calls `building.isLastFloor(_floor)` twice within the same execution frame: first to pass the authorization check, and second to assign the final state of the `top` variable. Because the `Elevator` contract blindly trusts the external implementation of `msg.sender`, an attacker can create a malicious contract that does not act purely. By maintaining an internal state variable, the attacker can force the same function to return two completely different boolean values during the exact same transaction.

### Exploit Path
1. **The Architecture:** Deploy a malicious `Attacker` contract that acts as the `Building`. It must contain a state variable (e.g., `bool public toggle = false;`) and implement the `isLastFloor(uint256)` function required by the target.
2. **The State Manipulation:** Inside `isLastFloor()`, write logic that flips the boolean `toggle` state every time it is called. 
3. **The Bypass:** Trigger the `attack()` function to call `target.goTo(1)`. 
    * On the first call from the target (the `if` statement check), the malicious function flips `toggle` to `true` and returns `false`, successfully bypassing the conditional block.
    * On the second call from the target (the state assignment), the malicious function flips `toggle` to `false` and returns `true`, permanently setting the Elevator's `top` variable to `true`.

### Execution
1. Deploy the malicious `Attacker` contract:
```bash
forge script script/11-Elevator.s.sol:DeployAttacker --rpc-url $SEPOLIA_RPC_URL --broadcast
```
2. Execute the payload to trigger the dual-return bypass and reach the top:
```bash
forge script script/11-Elevator.s.sol:DeployAttack --rpc-url $SEPOLIA_RPC_URL --broadcast
```

## 12 - Privacy
**Difficulty:** 3/5  
**Vulnerability:** Insecure On-Chain Data / Storage Slot Packing & Type Casting

### Analysis
The `Privacy` contract reinforces the concept that the `private` visibility modifier provides zero cryptographic security, but it adds the complexity of EVM storage packing and explicit type downcasting. Storage slots are exactly 32 bytes. The EVM packs contiguous variables into a single slot if they fit. Based on the target's source code, Slot 0 holds a `bool`, Slot 1 holds a `uint256` (requiring a new slot), and Slot 2 packs a `uint8`, `uint8`, and `uint16` together. A fixed-size array always begins in a fresh slot. Therefore, the `bytes32[3] private data` array occupies Slots 3, 4, and 5 sequentially. 

The unlock mechanism requires the `bytes16` equivalent of `data[2]`, which is stored in Slot 5. When downcasting a `bytes32` type to `bytes16`, Solidity truncates from the right side, preserving the highest-order (left-most) 16 bytes of the hexadecimal string. 

### Exploit Path
1. **Slot Calculation:** Map the target contract's state variables to identify that the required key (`data[2]`) resides entirely within Storage Slot 5.
2. **The Extraction:** Query the blockchain directly using `cast storage <TARGET_ADDRESS> 5` to read the raw 32-byte hexadecimal payload sitting in that specific slot.
3. **The Truncation & Unlock:** Inside the `Attacker` contract, explicitly cast the retrieved `bytes32` string into `bytes16`. Pass this cleanly truncated payload into the target's `unlock(bytes16)` function to bypass the check and permanently unlock the contract.

### Execution
1. Deploy the `Attacker` contract containing the pre-calculated, casted key:
```bash
forge script script/12-Privacy.s.sol:DeployAttacker --rpc-url $SEPOLIA_RPC_URL --broadcast
```

2. Execute the payload to trigger the unlock function:
```bash
forge script script/12-Privacy.s.sol:DeployAttack --rpc-url $SEPOLIA_RPC_URL --broadcast
```

## 13 - Gatekeeper One
**Difficulty:** 4/5  
**Vulnerability:** EVM Gas Metering / Bitwise Masking / Context Hijacking

### Analysis
The `GatekeeperOne` contract serves as a comprehensive exam on EVM execution architecture, data downcasting, and gas forwarding mechanics. It enforces three distinct "gates" that must be simultaneously bypassed within a single transaction.

*   **Gate One (`msg.sender != tx.origin`):** This enforces a strict execution context. It requires the attack to originate from a smart contract rather than an Externally Owned Account (EOA), as `tx.origin` evaluates to the top-level signer, while `msg.sender` evaluates to the immediate caller in the stack.
*   **Gate Two (`gasleft() % 8191 == 0`):** This exploits the EVM's strict gas-metering architecture. It requires the execution frame to have a specific gas remainder at the exact opcode where `gasleft()` is evaluated. Because EVM opcodes consume dynamic amounts of gas based on storage state (e.g., cold vs. warm access), this necessitates highly precise gas forwarding or an on-chain brute-force mechanism.
*   **Gate Three (Typecasting & Bitwise Logic):** This tests raw bitwise arithmetic and data loss during truncation. The requirement relies on converting a `bytes8` key through various integer sizes. 
    *   `uint32(uint64(key)) == uint16(uint160(tx.origin))` requires the lowest two bytes of the key to match the lowest two bytes of `tx.origin`.
    *   `uint32(uint64(key)) != uint64(key)` requires the upper 4 bytes (of the 8-byte key) to contain non-zero data, preventing a simple 1:1 downcast match.
    *   The bitmask `0xFFFFFFFF0000FFFF` mathematically guarantees these conditions by zeroing out bytes 5 and 6, while perfectly preserving the required boundary bytes.

### Exploit Path
1.  **The Key Generation:** Inside the attacker contract, extract the `tx.origin` address, downcast it to `uint64` to isolate the lowest 8 bytes, and apply the bitwise AND mask (`0xFFFFFFFF0000FFFF`) to structure the data for Gate 3.
2.  **The Context Hijack:** Deploy an intermediate `Attacker` contract to interface with the target, instantly satisfying Gate 1's origin check.
3.  **The On-Chain Brute Force:** Instead of pre-calculating the exact gas off-chain, initiate a loop inside the `attack()` function that executes low-level `.call` operations with sequentially incremented gas limits (`base + i`). The loop intercepts the boolean return values, shielding the parent frame from `OutOfGas` reverts, and gracefully exits the moment `8191` modulo alignment is achieved.

### Execution
1. Deploy the `Attacker` contract and execute the brute-force payload in a single transaction sequence using the combined deployment script:
```bash
forge script script/13-GateKeeperOne.s.sol:DeployAndAttack --rpc-url $SEPOLIA_RPC_URL --broadcast
```

## 15 - Naught Coin
**Difficulty:** 3/5
**Vulnerability:** Unprotected Alternate Transfer Path

### Analysis
The `NaughtCoin` contract extends OpenZeppelin's ERC-20 implementation and attempts to enforce a 10-year lockup period on the player's token balance. The protection mechanism is implemented by overriding the `transfer()` function and applying a custom `lockTokens` modifier.

This approach is fundamentally flawed because ERC-20 exposes multiple mechanisms for transferring tokens. While direct transfers are restricted, the contract inherits the standard `approve()` and `transferFrom()` functionality without additional access controls.

The critical architectural oversight is that `transfer()` and `transferFrom()` operate on different execution contexts:

*   `transfer()` debits tokens directly from msg.sender.
*   `transferFrom()` allows an approved spender to move tokens from an arbitrary `from` address.

Because the lock modifier only validates `msg.sender`, an attacker can approve a third-party contract to spend their tokens and subsequently invoke `transferFrom()`. During this execution:

*   `from` resolves to the player's address.
*   `msg.sender` resolves to the intermediary attacker contract.

As a result, the player's balance can be drained while completely bypassing the lock restriction.

### Exploit Path
1. **The Architecture:** Deploy an intermediary `Attacker.sol` contract capable of invoking `transferFrom()` on the target token.
2. **The Allowance:** From the player account, call `approve(attacker, INITIAL_SUPPLY)` on the `NaughtCoin` contract, granting the attacker contract permission to spend the entire token balance.
3. **The Bypass:** Trigger the `Attacker.transferMe()` function. The attacker contract executes:
```javascript

coin.transferFrom(
    player,
    address(this),
    coin.balanceOf(player)
);

```

4. **The Context Shift:** The target contract evaluates:

from       = player
msg.sender = attacker
Since the lock logic only validates `msg.sender`, the transfer succeeds while moving the player's complete balance to the attacker contract.

### Execution
1. Deploy the `Attacker` contract, approve the allowance, and execute the payload:
```bash
forge script script/15-NaughtCoin.s.sol:DeployAttacker --rpc-url $SEPOLIA_RPC_URL --broadcast
```

## 16-Preservation
**Difficulty:** 4/5
**Vulnerability:** Storage Collision via Unsafe `delegatecall`

### Analysis
The `Preservation` contract uses `delegatecall` to execute code from external library contracts:
```javascript
timeZone1Library.delegatecall(
    abi.encodePacked(setTimeSignature, _timeStamp)
);
```
`delegatecall` executes the callee's code using the caller's storage context. The library assumes it writes to its own `storedTime` variable at storage slot `0`, but during `delegatecall`, it actually writes to slot `0` of `Preservation`.

### Preservation Storage Layout         

| Slot | Variable           |
| ---- | ------------------ |
| 0    | `timeZone1Library` |
| 1    | `timeZone2Library` |
| 2    | `owner`            |
| 3    | `storedTime`       |

### LibraryContract Storage Layout

| Slot | Variable     |
| ---- | ------------ |
| 0    | `storedTime` |

### Exploit Path
1. Call `setFirstTime(uint256(uint160(address(attackerContract))))`. This overwrites timeZone1Library with the attacker's contract address.
2. Call `setFirstTime()` again. Since `timeZone1Library` now points to the malicious contract, delegatecall executes:
 ```javascript
 function setTime(uint256) public {
    owner = tx.origin;
 }
 ```
 The attacker contract mirrors the target's storage layout so that `owner` maps to slot `2`, overwriting `Preservation.owner`.
<details>
<summary>Attacker.sol</summary>

```javascript
contract Attacker {
    address public temporary1; // slot 0
    address public temporary2; // slot 1
    address public owner; // slot 2
    
    function setTime(uint256) public {
        owner = tx.origin;
    }

    function getOwner() public view returns (address) {
        return owner;
    }
}

```
</details>

### Execution
1. Deploy the `Attacker` Contract:
```bash
forge script script/16-Preservation.s.sol:DeployAttacker --rpc-url $SEPOLIA_RPC_URL --broadcast
```
2. Execute the exploit path
```bash
forge script script/16-Preservation.s.sol:DeployAttack --rpc-url $SEPOLIA_RPC_URL --broadcast
```

## 17-Recovery
**Difficulty:** 3/5  
**Vulnerability:** Predictable Contract Address  

### Analysis
The `Recovery` contract deploys `SimpleToken` contracts using the `CREATE` opcode:
```javascript
new SimpleToken(_name, msg.sender, _initialSupply);
```
Addresses created via `CREATE` are deterministic and depend only on the creator address and its nonce:
```javascript
address = keccak256(rlp.encode([creator, nonce]))[12:]
```
Since the target token was the first contract created by `Recovery`, its nonce is `1`.

### Exploit Path
1. Compute the lost contract address: `address lostContract = vm.computeCreateAddress(RECOVERY_ADDRESS,1);`
2. Cast the address to ISimpleToken.
3. Call: `target.destroy(payable(attacker));`

### Execution
1. Execute the exploit using:
```bash
forge script script/17-Recovery.s.sol:DeployAttack --rpc-url $SEPOLIA_RPC_URL --broadcast
```   

## 19 - Alien Codex
**Difficulty:** 4/5  
**Vulnerability:** Array length underflow leading to arbitrary storage write

### Analysis
The `AlienCodex` uses older solidity version which has unchecked arithmetic. The `retract` function results in decreasing length of the array which means the last element no longer accessed through the array.
```javascript
    function retract() public contacted {
        codex.length--;
    }
``` 
The issue is if the array is empty then calling `retract` results in length goes from `0` to `-1`, but because of unchecked arithmetic it becomes `2^256 - 1` and would not revert. Since the array length becomes `2^256 - 1`, almost every `uint256` index passes the bounds check. Because dynamic array elements are stored at `keccak256(p) + index`, we can choose an index that maps to any desired storage slot.
Let the storage slot for arrays length be `p` and if we want to read / write the storage slot `x`, then the required array index is :
`Index = (x - keccak256(p)) % 2^256`  OR  `Index = uint256.max - keccak256(p) + x + 1`
<details>
<summary>Proof</summary>

```javascript
p = storage slot of arrays length
x = storage slot we want to read / write

The arrays index i stores the value at storage slot: keccak256(p) + i
We want the storage slot x
let the arrays index be `i` for it

so, keccak256(p) + i = x
All calulations are performed modulo 2^256 

i = (x - keccak256(p)) mod 2^256
i = 2^256 + x - keccak256(p)
Add and subtract 1 
i = 2^256 - 1 + x - keccak256(p) + 1
2^256 - 1 is uint256.max

therefore, i = uint256.max - keccak256(p) + x + 1
```

</details>

In this challenge, we have three variables: address owner, bool contact and bytes32[] codex

```text
Storage Layout

slot 0
┌──────────────┬──────────┬────────────────────────────┐
│ 11 bytes     │ contact  │ owner                      │
│ unused       │ (1 byte) │ (20 bytes)                 │
└──────────────┴──────────┴────────────────────────────┘

slot 1
┌──────────────────────────────────────────────────────┐
│                codex.length (uint256)                │
└──────────────────────────────────────────────────────┘
```
Since codex.length is stored in storage slot 1, we have p = 1.
codex[i] storage slot would be : keccak256(1) + i

so, p = 1 and owner is at slot 0 which we want to alter so x = 0
by using this p and x, we can calculate the desired index of codex which we can alter to alter the owner's value using `revise` function.

### Exploit Path
1. Call `makeContact`. It will set the `contact` variable to `true` since all other functions require `contact` to be `true`.
2. At this stage, `codex` array would be empty. Call `retract`. It changes the array length from `0` to `2^256 - 1`, allowing us to choose an index that maps to any arbitrary storage slot.
3. Since `owner` occupies the lower 20 bytes of storage slot `0` (x = 0) and `codex` length is at storage slot `1` (p = 1), we calculate the index which maps `codex[index]` to storage slot `0` using the formula derived above.
4. Using `revise` we change the value of codex index (we just calculated) to our own address. Since that index corresponds to the owner's storage slot, our own address is written to that slot and the `owner` variable now stores our address. 

### Execution
1. Execute the exploit using:
```bash
forge script ./script/19-AlienCodex.s.sol:DeployAttack --rpc-url $SEPOLIA_RPC_URL --broadcast
``` 

## 20 - Denial
**Difficulty:** 3/5  
**Vulnerability:** Gas griefing via untrusted external call / gas based DoS

### Analysis
The `Denial` contract lets anyone to be a withdrawing partner. The `withdraw` function makes an untrusted external call before completing its own execution and forwards almost all of the remaining gas to the callee. Since `.call` forwards almost all of the remaining gas by default, the callee can consume nearly all of it.

In this challenge, an attacker can deploy a contract which burns a lot of gas (like having an infinite while loop in `receive` function), and can make it a withdrawing partner. When the `owner` calls `withdraw`, the `.call` forwards almost all of the remaining gas to the malicious contract (according to EIP-150, 63/64th of the remaining gas is forwarded and can be used by the malicious contract, and after the call the `Denial` contract ends up with 1/64th of remaining gas for rest of the executions). Therefore, if the remaining gas is not able to perform the rest of the execution, it will revert the whole transaction with OutOfGas.

Gas analysis of `withdraw` function:

```javascript
    function withdraw() public {

        //// BLOCK 1 //////////////////////////////////////////////
        uint256 amountToSend = address(this).balance / 100; ////// BURNS ~199 gas
        /////////////////////////////////////////////////////////

        partner.call{value: amountToSend}("");

        //// BLOCK 2 //////////////////////////////////////////////
        payable(owner).transfer(amountToSend);              //////
        timeLastWithdrawn = block.timestamp;               ////// BURNS ~27458 gas
        withdrawPartnerBalances[partner] += amountToSend; //////
        ///////////////////////////////////////////////////////
    }
```
The `owner` would give maximum of 1M gas for transaction to pass. Let's do some rough calculation around partner's call, finding how much has we have:
1. 1M = 1000000 gas available.
2. 1000000 - 199 = ~999801 gas remaining after Block 1.
3. Partner call opcode execution will burn some gas and 63/64th of leftover gas would be forwarded to partner's execution (the infinite loop consumes all the forwarded gas and halt with an out-of-gas exception).
4. So we have 1/64th leftover gas for Block 2, which is ~15621 (=999801/64) gas at most. But Block 2 execution requires ~27458 gas to complete! 
5. The partner contract consumes so much of the forwarded gas that the remaining gas is insufficient to execute Block 2. As a result, `withdraw` runs out of gas and reverts, preventing the owner from withdrawing funds.    

### Exploit Path
1. Deploy the `Attacker` contract. It has only `receive` function which execute infinite while loop.
2. Set `Attacker` contract as withdrawing partner by using `setWithdrawPartner`.
3. Whenever `owner` calls the `withdraw`, the process will run out of gas and revert out as gas would be insufficient for `withdraw` operations because `Attacker` consume most of it. 

### Execution
1. Execute the exploit path (done in single script):
```bash
forge script script/20-Denial.s.sol:DeployAttack --rpc-url $SEPOLIA_RPC_URL --broadcast
```

## 21 - Shop
**Difficulty:** 2/5  
**Vulnerability:** Trusting an untrusted external call  

### Analysis
The `Shop` contract interacts with a `Buyer` contract through an external `price()` view function. Although `price()` is a view function and cannot modify state, it can still read the state of other contracts, including `Shop`. In the `buy()` function, `Shop` contract make some checks and confirms that the price asked is more than the current `price` and whether it is sold or not. It first sets the `isSold` to `true` and then changes `price` to asked price, but here the contract assumes that repeated calls to `buyer.price()` return the same value and between the two calls to `buyer.price()`, the value of `isSold` changes from `false` to `true`.

A malicious `Buyer` can inspect `Shop.isSold()`. During the first call, `isSold` is `false`, so `price()` returns a value greater than or equal to the current price, allowing the purchase to proceed. After `Shop` sets `isSold = true`, it calls `price()` again. This time the buyer detects the changed state and returns a much lower price, which becomes the shop's final selling price.    

### Exploit Path
1. Deploy the `Buyer` contract. This contract should have a view function `price()` which returns two different values based on the value of `Shop.isSold()`. If `isSold` is `false`, return some high price (>= 100) and if `isSold` is `true`, return some low value (< 100). It has an another function for calling the `buy()` function of `Shop` contract.
2. Since `isSold` is declared `public`, Solidity automatically generates a getter function (`isSold()`). The attacker's `Buyer` contract can call this getter from within its `price()` function to determine whether the first or second call is being made.
3. `Buyer` calls `Shop.buy()`. During the first call to `price()`, `Shop.isSold()` is `false`, so `price()` returns a value greater than or equal to `100`, satisfying the purchase condition. After `Shop` sets `isSold = true`, it calls `price()` again to update its price. This time, `price()` returns a value less than `100`, causing the shop's final price to be updated to the lower value. 

### Execution
1. Execute the exploit using:
```bash
forge script script/21-Shop.s.sol:DeployAttack --rpc-url $SEPOLIA_RPC_URL --broadcast
```
