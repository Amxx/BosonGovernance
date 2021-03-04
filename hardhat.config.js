require('@nomiclabs/hardhat-truffle5');
require('@nomiclabs/hardhat-ethers');
require('solidity-coverage');
require('hardhat-gas-reporter');

const settings = {
  optimizer: {
    enabled: true,
    runs: 200,
  },
};

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      { version: '0.5.16', settings },
      { version: '0.6.12', settings },
      { version: '0.7.6',  settings },
      { version: '0.8.2',  settings },
    ],
  },
  gasReporter: {
    enable: true,
    currency: 'USD',
  },
};
