require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();
require("@nomiclabs/hardhat-etherscan");
require("hardhat-gas-reporter");
require("solidity-coverage");



module.exports = {
solidity: {
  compilers: [
      {
          version: "0.8.7",
          settings: {
              optimizer: {
                  enabled: true,
                  runs: 100
              }
          }
      },
  ],
},
defaultNetwork: "hardhat",
  networks: {
    hardhat: {
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [`${process.env.RINKEBY_PRIVATE_KEY}`]
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.MAINNET_API_KEY}`,
      accounts: [`${process.env.RINKEBY_PRIVATE_KEY}`]
    }
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    coinmarketcap: process.env.Coinmarketcap
  },
  etherscan : {
    apiKey : {
      rinkeby : process.env.EtherScanAPI,
      mainnet : process.env.EtherScanAPI
    } 
  }
}

















  



