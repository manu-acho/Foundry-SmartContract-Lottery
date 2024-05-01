# Raffle Lottery Smart Contract
# Overview

The Raffle Lottery contract is designed to create a decentralized and trustless lottery system where participants can enter a raffle by sending Ether. It leverages Chainlink VRF for secure and verifiable random number generation and Chainlink Automation for scheduled task execution, ensuring a fair and automated drawing process.

# Features

    1. Chainlink VRF Integration: Utilizes Chainlink's Verifiable Random Function to ensure that the winner selection process is provably fair and tamper-proof.
    2. Chainlink Automation: Automates the execution of lottery draws, reducing the need for manual intervention and ensuring timely operations.
    3. Checks-Effects-Interactions Pattern: Adopts this common security pattern to prevent reentrancy attacks.
    4. Flexible Ticket Pricing: Allows configuration of ticket prices upon deployment.
    5. Timed Draws: Configurable intervals for automatic lottery draws.

# Prerequisites

    1.Node.js and npm
    2.Foundry for smart contract development and testing
    3.Metamask for interacting with the Ethereum blockchain

# Smart Contracts
    1. Raffle.sol: Main contract for raffle management.
    2. DeployRaffle.s.sol: Script for deploying the Raffle contract and setting up dependencies.
    3. HelperConfig.s.sol: Configuration helper for network-specific settings.
    4. Interactions.s.sol: Includes scripts for creating and funding Chainlink VRF subscriptions.

# Installation
1. Clone the repository
```bash
git clone https://github.com/your-username/raffle-lottery-contract.git
cd raffle-lottery-contract
```
2. Install dependencies
```bash
forge install
```
3. Compile the contracts
```bash
forge build
```

# Configuration
Before deploying, configure the network settings and Chainlink parameters in the HelperConfig contract. Update the VRF Coordinator address, gas lane, subscription ID, and callback gas limit according to the network you are deploying to.

# Deployment
Deploy the contracts to your desired network using Foundry: - See MakeFile
```bash
forge script script/DeployRaffle.s.sol $(NETWORK_ARGS)
```
This will deploy the Raffle contract and configure it with the necessary Chainlink services.

# Usage
After deployment, participants can enter the raffle by sending the required Ether amount to the contract. The Chainlink Keeper will automatically trigger the draw based on the predefined interval, and the Chainlink VRF will select a random winner.

# Testing
Run the automated tests to ensure the contracts work as expected:
```bash
forge test
```
# Security
This project uses industry-standard security practices and patterns to ensure the integrity of the raffle process. Review the smart contract code and conduct thorough testing and audits before using in production.

# Contributing
Contributions are welcome! Please feel free to submit pull requests or open issues to improve the code or add new features.

