# Description

NFT Marketplace + Auction for Tezos

# Architecture

The solution consists of 3 types of contracts:

1. `FA2` - NFT Token contract;
2. `Auction` - contract for interaction with the auction;
3. `Market` - contract for interaction with the marketplace.

# Project structure

```
.
├──  contracts/ # contracts
|──────── main/ # the contracts to be compiled
|──────── partial/ # the code parts imported by main contracts
├──  scripts/sandbox # cli for test and deployment addresses
├──  README.md # current file
├──  .gitignore
└──  package.json
```

# Prerequisites

- Installed NodeJS (tested with NodeJS v12+)

- Installed Yarn (NPM isn't working properly with `ganache-cli@6.12.0-tezos.0`)

- Installed Ligo:

```
curl https://gitlab.com/ligolang/ligo/raw/dev/scripts/installer.sh | bash -s "next"
```

- Installed node modules:

```
cd blockchain_ua_2021 && yarn
```

- Configure `truffle-config.js` if [needed](https://www.trufflesuite.com/docs/tezos/truffle/reference/configuring-tezos-projects).

# Quick Start

To compile and deploy contracts to EdoNet

```
yarn migrate-edonet
```

For other networks:

```
yarn migrate --network NAME # other networks
```

# Usage

Contracts are processed in the following stages:

1. Compilation
2. Deployment
3. Configuration
4. Interactions on-chain

## Compilation

To compile the contracts run:

```
yarn compile
```

Artifacts are stored in the `build/contracts` directory.

## Deployment

For deployment step the following command should be used:

```
yarn migrate
```

Addresses of deployed contracts are displayed in terminal

# Contract links :
1. [Auction](https://better-call.dev/edo2net/KT1L73Nh5KquNpFJHzMz2v4QrpVtLFXrgEGa/operations)
2. [Market](https://better-call.dev/edo2net/KT1NLVYVFQfbtCD4t8hFy4MJv6yMgagUHE1H/operations)
3. [FA2](https://better-call.dev/edo2net/KT1Ni1cYKkUEXxPUVDCiV6SinnozHhJM6wSP/operations)

# GitHubs of participants :
1. [Sergey Makov - Smart Contract Dev](https://github.com/smak0v)
2. [Oleh Rubanik - Smart Contract Dev](https://github.com/rubanik00)
3. [Oleh Khalin - Front-End Dev](https://github.com/olehkhalin)

# [Front-end](https://da-vinci-marketplace-ui.vercel.app/)
