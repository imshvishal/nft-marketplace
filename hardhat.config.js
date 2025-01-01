require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

let PRIVATE_KEYS = [process.env.OWNER_PRIVATE_KEY, process.env.USER1_PRIVATE_KEY];

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    thunder: {
      url: "https://rpc.testnet.5ire.network",
      chainId: 997,
      accounts: PRIVATE_KEYS
    }
  },
  etherscan: {
    apiKey: {
      thunder: process.env.THUNDER_API_KEY !== undefined ? [process.env.THUNDER_API_KEY] : []
    },
    customChains: [
      {
        network: "thunder",
        chainId: 997,
        urls: {
          apiURL: "https://contract.evm.testnet.5ire.network/5ire/verify",
          browserURL: "https://testnet.5irescan.io/dashboard"
        }
      }
    ]
  }
};