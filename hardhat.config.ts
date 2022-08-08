import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.9",
  networks: {
    hardhat: {
      throwOnTransactionFailures: true,
      throwOnCallFailures: true
    }
  }
};

export default config;
