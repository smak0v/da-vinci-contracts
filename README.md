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

# Entrypoints

The Ligo interfaces of the contracts can be found in `contracts/partials/I__CONTRACT_NAME__.ligo`

## Auction

