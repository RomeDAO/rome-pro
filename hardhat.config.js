require("@nomiclabs/hardhat-waffle");
import {node_url, accounts, getChainId} from './utils/network';

module.exports = {
  solidity: "0.7.5",
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