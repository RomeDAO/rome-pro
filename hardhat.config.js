require("@nomiclabs/hardhat-waffle");
const {node_url, accounts, getChainId, apiKey} = require('./utils/network.js')
// import {node_url, accounts, getChainId} from ;

module.exports = {
  solidity: {
    compilers: [
      {
        version:'0.7.5',
        settings: {
          optimizer: {
            enabled: true,
            runs: 9999,
          }
        }
      },
      {
        version: '0.5.0',
        settings: {
          optimizer: {
            enabled: true,
            runs: 9999,
          }
        }
      },
      {
        version:'0.5.16',
        settings: {
          optimizer: {
            enabled: true,
            runs: 9999,
          }
        }
      },
    ]
  },
  networks: {
    localhost: {
      url: node_url('localhost'),
      accounts: accounts(),
    },
    moonriver: {
      url: node_url('moonriver'),
      chainId: getChainId('moonriver'),
      accounts: accounts('moonriver'),
      live: true,
      saveDeployments: true,
      tags: ['moonriver'],
      gasPrice: 2000000000,
      gas: 8000000,
    },
    moonbase: {
      url: node_url('moonbase'),
      chainId: getChainId('moonbase'),
      accounts: accounts('moonbase'),
      live: true,
      saveDeployments: true,
      tags: ['moonbase'],
      gasPrice: 2000000000,
      gas: 8000000,
    }
  },
  etherscan : {
    // Your API key for Etherscan
    // Obtain one at httpsL//etherscan.io/
    apiKey: apiKey('moonriver')
  }
};