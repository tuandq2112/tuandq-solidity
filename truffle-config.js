var HDWalletProvider = require("truffle-hdwallet-provider");
var infuraId = "3e31b3e72c8c4e798f5a2a61cf0ec50e";
var privateKeys = [
  "fb48ab6b9df7c3ee7adc24c1dbe0b3875aaf88871d44be340ebe7db8ebe314c8",
];
module.exports = {
  networks: {
    development: {
      host: "127.0.0.1", // Localhost (default: none)
      port: 8545, // Standard Ethereum port (default: none)
      network_id: "*", // Any network (default: none)
    },
    develop: {
      host: "127.0.0.1", // Localhost (default: none)
      port: 9545, // Standard Ethereum port (default: none)
      network_id: "*",
    },
    rinkeby: {
      provider: () =>
        new HDWalletProvider(
          privateKeys,
          `https://rinkeby.infura.io/v3/${infuraId}`
        ),
      network_id: 4, // Ropsten's id
      gas: 5500000, // Ropsten has a lower block limit than mainnet
      confirmations: 2, // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200, // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true, // Skip dry run before migrations? (default: false for public nets )
    },
    bnbt: {
      provider: () =>
        new HDWalletProvider(
          privateKeys,
          `https://data-seed-prebsc-1-s1.binance.org:8545`
        ),
      network_id: 97,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true,
      from: 0,
    },
    bsc: {
      provider: () =>
        new HDWalletProvider(privateKeys, `https://bsc-dataseed.binance.org`),
      network_id: 56,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true,
      from: 0,
    },
  },

  mocha: {},

  compilers: {
    solc: {
      version: "0.8.4",
    },
  },
};
