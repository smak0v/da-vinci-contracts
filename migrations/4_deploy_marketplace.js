const Market = artifacts.require("Market");

const { TezosToolkit } = require("@taquito/taquito");
const { InMemorySigner } = require("@taquito/signer");
const { MichelsonMap } = require("@taquito/michelson-encoder");

const { oleh } = require("../scripts/sandbox/accounts");

module.exports = async (deployer, _network, accounts) => {
  tezos = new TezosToolkit(tezos.rpc.url);
  tezos.setProvider({
    config: {
      confirmationPollingTimeoutSecond: 500,
    },
    signer: await InMemorySigner.fromSecretKey(oleh.sk),
  });

  const storage = {
    tokenFa2: "KT1PD7P87iCMLLQEsubaoENoT71FgE4XeJeg",
    admin: oleh.pkh,
    tokensByUser: new MichelsonMap(),
    marketsByToken: new MichelsonMap(),
    markets: new MichelsonMap(),
    marketsByUser: new MichelsonMap(),
    lastTokenId: "0",
    fee: "500000"
  };

  await deployer.deploy(Market, storage);
};
