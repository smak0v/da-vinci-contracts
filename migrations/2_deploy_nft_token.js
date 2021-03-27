const FA2 = artifacts.require("FA2");

const { oleh } = require("../scripts/sandbox/accounts");

const { TezosToolkit } = require("@taquito/taquito");
const { InMemorySigner } = require("@taquito/signer");
const { MichelsonMap } = require("@taquito/michelson-encoder");

module.exports = async (deployer, _network, accounts) => {
  tezos = new TezosToolkit(tezos.rpc.url);
  tezos.setProvider({
    config: {
      confirmationPollingTimeoutSecond: 500,
    },
    signer: await InMemorySigner.fromSecretKey(oleh.sk),
  });

  const storage = {
    ledger: new MichelsonMap(),
    token_metadata: new MichelsonMap(),
    metadata: new MichelsonMap(),
    lastTokenId: "0",
  };

  await deployer.deploy(FA2, storage);
};
