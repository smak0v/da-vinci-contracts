const Auction = artifacts.require("Auction");

const { oleh } = require("../scripts/sandbox/accounts");

const { MichelsonMap } = require("@taquito/michelson-encoder");
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

  const storage = {
    auctions: new MichelsonMap(),
    auctionByToken: new MichelsonMap(),
    auctionsByUser: new MichelsonMap(),
    tokensByUser: new MichelsonMap(),
    admin: oleh.pkh,
    token: "KT1PD7P87iCMLLQEsubaoENoT71FgE4XeJeg",
    lastAuctionId: "0",
    minAuctionLifetime: "3600", // 1 hour
    maxExtensionTime: "21600", // 6 hours
  };

  await deployer.deploy(Auction, storage);
};
