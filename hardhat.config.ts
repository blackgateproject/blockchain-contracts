import "@matterlabs/hardhat-zksync";
import "@typechain/hardhat";
import dotenv from "dotenv";
import "hardhat-abi-exporter";
import { HardhatUserConfig } from "hardhat/config";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v6",
  },
  abiExporter: {
    // more info about this plugin in https://www.npmjs.com/package/hardhat-abi-exporter
    path: "./abis",
    runOnCompile: true,
    clear: true,
    flat: true,
    spacing: 2,
    pretty: true,
  },
  defaultNetwork: "dockerizedNode",
  // defaultNetwork: "zkSyncSepoliaTestnet",
  networks: {
    zkSyncSepoliaTestnet: {
      url: "https://sepolia.era.zksync.dev",
      ethNetwork: "sepolia",
      zksync: true,
      verifyURL:
        "https://explorer.sepolia.era.zksync.dev/contract_verification",
      accounts: process.env.WALLET_PRIVATE_KEY
        ? [process.env.WALLET_PRIVATE_KEY]
        : [],
    },
    zkSyncMainnet: {
      url: "https://mainnet.era.zksync.io",
      ethNetwork: "mainnet",
      zksync: true,
      verifyURL:
        "https://zksync2-mainnet-explorer.zksync.io/contract_verification",
      accounts: process.env.WALLET_PRIVATE_KEY
        ? [process.env.WALLET_PRIVATE_KEY]
        : [],
    },
    dockerizedNode: {
      url: "http://localhost:3050",
      ethNetwork: "http://localhost:8545",
      zksync: true,
      accounts: process.env.WALLET_PRIVATE_KEY
        ? [process.env.WALLET_PRIVATE_KEY]
        : [],
    },
    anvilZKsync: {
      url: "http://127.0.0.1:8011",
      ethNetwork: "localhost", // in-memory node doesn't support eth node; removing this line will cause an error
      zksync: true,
      accounts: process.env.WALLET_PRIVATE_KEY
        ? [process.env.WALLET_PRIVATE_KEY]
        : [],
    },
    hardhat: {
      zksync: true,
    },
  },
  zksolc: {
    version: "latest",
    settings: {
      // find all available options in the official documentation
      // https://docs.zksync.io/build/tooling/hardhat/hardhat-zksync-solc#configuration
    },
  },
};

export default config;
