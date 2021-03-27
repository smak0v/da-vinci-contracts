const FA2 = artifacts.require("FA2");

const { MichelsonMap } = require("@taquito/michelson-encoder");

module.exports = async (deployer, _network, accounts) => {
  const storage = {
    ledger: new MichelsonMap(),
    token_metadata: new MichelsonMap(),
    metadata: new MichelsonMap(),
    lastTokenId: "0",
  };

  await deployer.deploy(FA2, storage);
};
