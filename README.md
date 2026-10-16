## TRUSTLANCE
TrustLance is a blockchain-powered freelance marketplace designed to improve trust, transparency, and accountability between clients and freelancers.

Traditional freelance arrangements can expose both parties to problems such as delayed payments, disagreements over deliverables, unclear project expectations, and uncertainty about whether either party will fulfill their obligations. Clients may worry about paying for incomplete work, while freelancers may worry about completing work without receiving payment.

TrustLance addresses these challenges by using smart contracts to manage important stages of a freelance engagement. These stages include job creation, negotiation, acceptance, funding, milestone submission, review, payment release, and dispute handling.

The central concept is escrow. Rather than relying entirely on a person or centralized platform to manage the payment process, the system uses programmable blockchain rules to govern how funds are handled.

The smart contract is written in Solidity and developed using Foundry. The frontend is built with React and Vite, while wallet connectivity is implemented with Reown AppKit, Wagmi, and Viem. The application is intended to interact with the Ethereum blockchain, initially through the Sepolia testnet.

The frontend has been deployed using Vercel, making the website accessible online. The remaining critical technical work is to confirm a successful smart contract deployment, configure the verified contract address and ABI in the frontend, and test the complete user journey against the deployed contract.

TrustLance demonstrates how blockchain technology can be applied to a practical problem in the digital economy: creating a more transparent and accountable process for managing freelance work and payments.

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
