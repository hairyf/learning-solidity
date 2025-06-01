# Learning Solidity

A collection of Solidity smart contracts and exercises to learn the language and its ecosystem.

This repository is developed and tested using [Hardhat 3](https://hardhat.org/hardhat3-alpha) and [forge-std](https://github.com/foundry-rs/forge-std).

## Project Overview

This project aims to provide a structured environment to help developers learn the Solidity programming language and Ethereum smart contract development. Through this repository, you can:

- Learn Solidity language fundamentals
- Understand smart contract development best practices
- Use modern toolchains (Hardhat 3) for development and testing
- Explore common smart contract patterns and libraries (such as OpenZeppelin)

## Tech Stack

- **Solidity 0.8.28**: Smart contract programming language
- **Hardhat 3**: Ethereum development environment
- **Foundry/forge-std**: Smart contract development toolkit
- **OpenZeppelin Contracts**: Secure smart contract library
- **TypeScript**: For scripts and testing
- **Viem/Ethers.js**: Ethereum JavaScript libraries

## Project Structure

```
learning-solidity/
├── contracts/         # Solidity smart contracts
├── test/              # Test files
├── ignition/          # Hardhat Ignition deployment modules
│   ├── deployments/   # Deployment records
│   └── modules/       # Deployment modules
```

## Installation

Make sure you have Node.js (v18+ recommended) and pnpm installed.

```bash
# Clone the repository
git clone https://github.com/hairyf/learning-solidity.git
cd learning-solidity

# Install dependencies
pnpm install
```

## Usage Guide

### Compile Contracts

```bash
npx hardhat compile
```

### Run Tests

```bash
npx hardhat test
```

### Deploy Contracts

Using Hardhat Ignition for deployment:

```bash
npx hardhat ignition deploy ./ignition/modules/your-module.ts
```

## Development Workflow

1. Write Solidity smart contracts in the `contracts/` directory
2. Write `.t.sol` test contracts, or write ts tests for your contracts in the `test/` directory
3. Compile and test your contracts using the Hardhat toolchain
4. Create Ignition modules for deployment

## Learning Resources

- [Solidity Documentation](https://docs.soliditylang.org/)
- [Hardhat Documentation](https://hardhat.org/docs)
- [Foundry Documentation](https://book.getfoundry.sh/)
- [OpenZeppelin Documentation](https://docs.openzeppelin.com/)

## License

[MIT](./LICENSE.md) License © [Hairyf](https://github.com/hairyf)
