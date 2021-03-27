const { alice } = require("./scripts/sandbox/accounts");

module.exports = {
  contracts_directory: "./contracts/main",
  networks: {
    development: {
      host: "http://localhost",
      port: 8732,
      network_id: "*",
      secretKey: alice.sk,
      type: "tezos",
    },
    development_2: {
      host: "http://136.244.96.28",
      port: 8732,
      network_id: "*",
      secretKey: alice.sk,
      type: "tezos"
    },
    edonet: {
      host: "https://testnet-tezos.giganode.io",
      port: 443,
      network_id: "*",
      secretKey: alice.sk,
      type: "tezos",
    },
    mainnet: {
      host: "https://mainnet.smartpy.io",
      port: 443,
      network_id: "*",
      type: "tezos",
    },
  },
};
