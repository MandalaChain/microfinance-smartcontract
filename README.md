# Mandala Chain ↔ Microfinance Smart Contract
## Overview

This repository showcases aims to foster adoption and enhance microfinance solutions.The core element of this repository is a Hardhat-based smart contract suite that implements registration and delegation functionalities for creditors and debtors. These contracts collectively manage data-sharing requests, purchase of packages, and the essential on-chain registration of users.

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Smart Contracts](#smart-contracts)
   - [DataSharing.sol](#datasharingsol)
   - [Delegation.sol](#delegationsol)
   - [Registration.sol](#registrationsol)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
5. [Scripts and Commands](#scripts-and-commands)
   - [Compile Contracts](#compile-contracts)
   - [Run Tests](#run-tests)
   - [Local Node](#local-node)
   - [Deploy Scripts](#deploy-scripts)
   - [Verification](#verification)
6. [Usage and Development](#usage-and-development)
   - [Environment Configuration](#environment-configuration)
   - [Contract Deployment](#contract-deployment)
   - [Interacting with the Contracts](#interacting-with-the-contracts)
7. [Testing](#testing)

---

## Project Structure
```
├─ contracts/ 
│ ├─ core/ 
│ │ ├─ Delegation.sol 
│ │ └─ Registration.sol 
│ ├─ DataSharing.sol 
│ └─ ... 
├─ scripts/ 
│ ├─ 1_deploy.ts 
│ ├─ 1_verify.ts 
├─ test/ 
│ ├─ index.ts
├─ package.json 
├─ hardhat.config.ts
├─ README.md (this file) 
└─ ...
```

- **contracts/**:
  - **core/**: Contains base contracts like `Delegation.sol` and `Registration.sol`.
  - **DataSharing.sol**: Main contract extending `Delegation` and providing higher-level functionality for data sharing and package purchases.

- **scripts/**: Deployment and setup scripts for various environments.

- **test/**: Contains unit/integration tests for each contract.

---

## Smart Contracts

### DataSharing.sol

- **Inherits** from:
  - [`Delegation.sol`](#delegationsol) → [`Registration.sol`](#registrationsol)
  - `Ownable` (from OpenZeppelin)

- **Key Responsibilities**:
  1. **Platform Management**: Authorizes a `_platform` address for sensitive operations.
  2. **Event Emissions**: 
     - Tracks creditor and debtor registrations with metadata.
     - Logs delegation requests and approvals.
     - Logs purchase package events.
  3. **High-Level Registration**: Adds/removes creditors and debtors, ensuring only the platform can call these methods.
  4. **Delegation Flow**: Requests delegation (consumer → provider), and provider approves or rejects.
  5. **Purchase Packages**: Records on-chain events for package acquisitions without storing large data structures.

### Delegation.sol

- **Inherits** from: [`Registration.sol`](#registrationsol)

- **Key Responsibilities**:
  1. **Delegation Requests**: 
     - `_requestDelegation` handles the creation of a delegation request from one creditor (consumer) to another (provider).
     - `_delegate` allows the provider to approve or reject a request.
  2. **Status Management**: Keeps track of **PENDING**, **APPROVED**, **REJECTED** states.
  3. **Storage**: 
     - Maintains a `_debtorInfo` mapping for each debtor, storing creditors and their statuses.
     - Maintains a `_request` mapping for delegation requests between consumer-provider pairs.

### Registration.sol

- **Base Contract** providing:
  1. **Mappings**: `_debtors` and `_creditors`, storing `(hash → address)` relationships.
  2. **Core Functions**: 
     - `_addDebtor`, `_addCreditor` → Register new participants.
     - `_removeDebtor`, `_removeCreditor` → Deregister participants.
  3. **Validation**: Checks for zero-address, zero-hash, or duplicate entries.

---

## Prerequisites

1. **Node.js (>= 18)** and **pnpm**  
2. **Hardhat** globally or run locally with `npx`.
3. A valid environment for test or deployment (e.g., local Hardhat node, Ganache, or public test network like Goerli/Polygon Mumbai).

---

## Installation

Clone the repository and install dependencies:

```bash
git clone https://github.com/baliola/microfinance-smartcontract.git
cd microfinance-smartcontract

# Install dependencies
pnpm install
```
---
## Scripts and Commands
Below is a list of useful scripts defined in `package.json`. Use `pnpm run <command>`.

### Compile Contracts
Forces a clean compilation of the Solidity contracts:
```bash
pnpm run compile
```

### Run Tests
Executes the test suite:
```bash
pnpm run test
```

### Local Node
Spins up a local Hardhat development blockchain:
```bash
pnpm run local-node
```

### Deploy Scripts
Deploy contracts to your local node or a specified network:
```bash
pnpm run deploy:contract

# Deploy to a local Hardhat node
pnpm run deploy:localhost

# Deploy to a configured remote network
pnpm run deploy:contract -- --network <your-network>
```

### Verification
If you're deploying to a public network (e.g., Etherscan-supported networks), you can verify the contracts:
```bash
pnpm run verify -- --network <your-network>

# Override the address if needed
VERIFY_ADDRESS=0xYourContractAddress pnpm run verify -- --network <your-network>
```

---

## Usage and Development
Environment Configuration
Create a .env file in the root directory (if not already present) with relevant settings:
```makefile
NETWORK_TESTNET_URL=https://abcde
NETWORK_TESTNET_PRIVATE_KEY=0xasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasda
NETWORK_MAINNET_URL=https://abcde
NETWORK_MAINNET_PRIVATE_KEY=0xnasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasda

BLOCK_EXPLORER_API_KEY=
GAS_REPORTER_COIN_MARKET_CAP_API_KEY=
```
In your `hardhat.config.ts`, reference these values to configure networks, e.g.:
```ts
networks: {
    hardhat: {
      chainId: 1337,
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 1337,
    },
    mandalaTestnet: {
      url: 'https://rpc1-testnet.mandalachain.io',
      chainId: 20011,
      accounts: process.env.NETWORK_TESTNET_PRIVATE_KEY ? [process.env.NETWORK_TESTNET_PRIVATE_KEY] : [],
    },
    mandalaMainnet: {
      url: 'https://rpc1-mainnet.mandalachain.io',
      chainId: 20010,
      accounts: process.env.NETWORK_MAINNET_PRIVATE_KEY ? [process.env.NETWORK_MAINNET_PRIVATE_KEY] : [],
    },
  },
```

### Contract Deployment
1. Local Deployment:
    - Run `pnpm run local-node` in one terminal to start a local Hardhat node.
    - In a new terminal, run `pnpm run deploy:localhost` to deploy the contracts.
2. Public Testnet/Mainnet:
    - Configure your `.env` with the correct keys and network details.
    - Update network settings in `hardhat.config.ts`.
    - Run the deploy script with the `--network <networkName>` option, for example:
      ```bash
      pnpm run deploy:contract -- --network <your-network>
      ```

### Interacting with the Contracts
- Hardhat console:
  ```bash
  pnpm exec hardhat console --network localhost
  ```
- Scripts:
Additional setup scripts such as `scripts/1_deploy.ts` and `scripts/1_verify.ts` demonstrate the deploy and verification flow for the `DataSharing` contract.

--- 

## Testing
All tests reside in the `test/` folder. Each contract has a corresponding test file `index.ts`. Tests cover:

- Registration: Adding/removing creditors and debtors, validation checks.
- Delegation: Requesting, approving, and rejecting delegation.
- DataSharing: Purchasing packages, setting the platform address, event emissions.
Running:
```bash
pnpm run test
```
Use `test-gas` or `test-extended` for different reporting modes.
