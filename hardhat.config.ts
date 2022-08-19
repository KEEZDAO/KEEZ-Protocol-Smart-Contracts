import { HardhatUserConfig } from "hardhat/config";

import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      throwOnTransactionFailures: true,
      throwOnCallFailures: true
    },
    luksoL16: {
      url: "https://rpc.l16.lukso.network",
      chainId: 2828,
      //   accounts: [privateKey1, privateKey2, ...]
    },
  },
  etherscan: {
    // no API is required to verify contracts
    // via the Blockscout instance of L14 or L16 network
    apiKey: "no-api-key-needed",
    customChains: [
      {
        network: "luksoL16",
        chainId: 2828,
        urls: {
          apiURL: "https://explorer.execution.l16.lukso.network/api",
          browserURL: "https://explorer.execution.l16.lukso.network/",
        },
      },
    ],
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    gasPrice: 21,
    src: "./contracts",
    showMethodSig: true,
  },
  solidity: {
    version: "0.8.7",
    settings: {
      optimizer: {
        enabled: true,
        /**
         * Optimize for how many times you intend to run the code.
         * Lower values will optimize more for initial deployment cost, higher
         * values will optimize more for high-frequency usage.
         * @see https://docs.soliditylang.org/en/v0.8.6/internals/optimizer.html#opcode-based-optimizer-module
         */
        runs: 1000,
      },
    },
  }
};

export default config;
