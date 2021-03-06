const Migrations = artifacts.require("Migrations");

const { oleh } = require("../scripts/sandbox/accounts");

const { TezosToolkit } = require("@taquito/taquito");
const { InMemorySigner } = require("@taquito/signer");

module.exports = async (deployer, _network, accounts) => {
  tezos = new TezosToolkit(tezos.rpc.url);
  tezos.setProvider({
    config: {
      confirmationPollingTimeoutSecond: 500,
    },
    signer: await InMemorySigner.fromSecretKey(oleh.sk),
  });

  await deployer.deploy(Migrations, {
    last_completed_migration: 0,
    owner: accounts[0],
  });
};
