const Auction = artifacts.require("Auction");

const { oleh } = require("../scripts/sandbox/accounts");

const { MichelsonMap } = require("@taquito/michelson-encoder");

module.exports = async (deployer, _network, accounts) => {
  const storage = {
    auctions: new MichelsonMap(),
    auctionByToken: new MichelsonMap(),
    auctionsByUser: new MichelsonMap(),
    tokensByUser: new MichelsonMap(),
    admin: oleh.pkh,
    token: ...,
    lastAuctionId: "0",
    minAuctionLifetime: "3600", // 1 hour
    maxExtensionTime: "21600", // 6 hours
  };

  deployer.deploy(Auction, storage);
};
