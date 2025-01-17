import fs from 'fs';
import * as dotenv from "dotenv";
import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import CollectionConfig from "./config/CollectionConfig";

dotenv.config();
const DEFAULT_GAS_MULTIPLIER: number = 1;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});
task(
  "rename-contract",
  "Renames the smart contract replacing all occurrences in source files",
  async (taskArgs: { newName: string }, hre) => {
    // Validate new name
    if (!/^([A-Z][A-Za-z0-9]+)$/.test(taskArgs.newName)) {
      throw "The contract name must be in PascalCase: https://en.wikipedia.org/wiki/Camel_case#Variations_and_synonyms";
    }

    const oldContractFile = `${__dirname}/contracts/${CollectionConfig.contractName}.sol`;
    const newContractFile = `${__dirname}/contracts/${taskArgs.newName}.sol`;

    if (!fs.existsSync(oldContractFile)) {
      throw `Contract file not found: "${oldContractFile}" (did you change the configuration manually?)`;
    }

    if (fs.existsSync(newContractFile)) {
      throw `A file with that name already exists: "${oldContractFile}"`;
    }

    // Replace names in source files
    replaceInFile(
      __dirname + "/config/CollectionConfig.ts",
      CollectionConfig.contractName,
      taskArgs.newName
    );
    replaceInFile(
      __dirname + "/lib/NftContractProvider.ts",
      CollectionConfig.contractName,
      taskArgs.newName
    );
    replaceInFile(
      oldContractFile,
      CollectionConfig.contractName,
      taskArgs.newName
    );

    // Rename the contract file
    fs.renameSync(oldContractFile, newContractFile);

    console.log(
      `Contract renamed successfully from "${CollectionConfig.contractName}" to "${taskArgs.newName}"!`
    );

    // Rebuilding types
    await hre.run("typechain");
  }
).addPositionalParam("newName", "The new name");

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.28',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 1337,
    },
    truffle: {
      url: 'http://localhost:24012/rpc',
      timeout: 60000,
      gasMultiplier: DEFAULT_GAS_MULTIPLIER,
    },
    niskala: {
      url: 'https://mlg1.mandalachain.io',
      chainId: 6025,
      accounts: process.env.NETWORK_TESTNET_PRIVATE_KEY ? [process.env.NETWORK_TESTNET_PRIVATE_KEY] : [],
    },
    devnet: {
      url: 'https://nbs.mandalachain.io',
      chainId: 895670,
      accounts: process.env.NETWORK_TESTNET_PRIVATE_KEY ? [process.env.NETWORK_TESTNET_PRIVATE_KEY] : [],
    },
  },
  gasReporter: {
    // enabled: process.env.REPORT_GAS ? true : false,
    enabled : true,
    currency: 'USD',
    coinmarketcap: process.env.GAS_REPORTER_COIN_MARKET_CAP_API_KEY,
    // outputFile : 'gass-report.txt',
  },
  etherscan: {
    apiKey: {
      // Ethereum
      goerli: process.env.BLOCK_EXPLORER_API_KEY!,
      sepolia: process.env.BLOCK_EXPLORER_API_KEY!,
      rinkeby: process.env.BLOCK_EXPLORER_API_KEY!,
      mainnet: process.env.BLOCK_EXPLORER_API_KEY!,
      // Polygon
      polygon: process.env.BLOCK_EXPLORER_API_KEY!,
      amoy: process.env.BLOCK_EXPLORER_API_KEY!,
      // Arbitrum
      arbitrumGoerli: process.env.BLOCK_EXPLORER_API_KEY!,
      arbitrumOne: process.env.BLOCK_EXPLORER_API_KEY!,
      // Niskala
      niskala: process.env.BLOCK_EXPLORER_API_KEY!,
      devnet: process.env.BLOCK_EXPLORER_API_KEY!,
    },
    customChains: [
      {
        network: "amoy",
        chainId: 80002,
        urls: {
          apiURL: "https://api-amoy.polygonscan.com/api",
          browserURL: "https://amoy.polygonscan.com/"
        }
      },
      {
        network: "niskala",
        chainId: 6025,
        urls: {
          apiURL: "https://niskala.mandalachain.io/api",
          browserURL: "https://niskala.mandalachain.io"
        }
      },
      {
        network: "devnet",
        chainId: 895670,
        urls: {
          apiURL: "https://nbs-explorer.mandalachain.io/api",
          browserURL: "https://https://nbs-explorer.mandalachain.io"
        }
      },
    ],
  },
};

// Setup "testnet" network
if (process.env.NETWORK_TESTNET_URL !== undefined) {
  config.networks!.testnet = {
    url: process.env.NETWORK_TESTNET_URL,
    accounts: [process.env.NETWORK_TESTNET_PRIVATE_KEY!],
    gasMultiplier: DEFAULT_GAS_MULTIPLIER,
  };
}

// Setup "mainnet" network
if (process.env.NETWORK_MAINNET_URL !== undefined) {
  config.networks!.mainnet = {
    url: process.env.NETWORK_MAINNET_URL,
    accounts: [process.env.NETWORK_MAINNET_PRIVATE_KEY!],
    gasMultiplier: DEFAULT_GAS_MULTIPLIER,
  };
}

export default config;

/**
 * Replaces all occurrences of a string in the given file. 
 */
function replaceInFile(file: string, search: string, replace: string): void
{
  const fileContent = fs.readFileSync(file, 'utf8').replace(new RegExp(search, 'g'), replace);

  fs.writeFileSync(file, fileContent, 'utf8');
}
