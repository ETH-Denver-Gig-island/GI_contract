import "@nomicfoundation/hardhat-toolbox";
require("dotenv").config();

// const hre = require('hardhat');
const ethers = require("ethers");
const provider = new ethers.providers.getDefaultProvider(
    "http://127.0.0.1:8545/"
);
// const wallet = new ethers.Wallet(process.env.WALLET_SECRET).connect(provider);
const gasPrice = ethers.utils.formatUnits(
    ethers.utils.parseUnits("10", "gwei"),
    "wei"
);

module.exports = {
    solidity: "0.8.17",
    defaultNetwork: "hardhat",
    gasPrice: parseInt(gasPrice),
    paths: {
        artifacts: "./src/artifacts",
        cache: "./cache",
    },
    // npx hardhat run --network localhost scripts/deploy.js
    networks: {
        hardhat: {
            chainId: 31337,
            initialBaseFeePerGas: 0,
            loggingEnabled: true,
            type: "hardhat",
            gasPrice: parseInt(gasPrice),
        },
        // localhost_fork: {
        //   chainId: 31337,
        //   forking: {
        //     url: process.env.MAINNET_RPC_URL,
        //     blockNumber: 16024306,
        //   },
        //   url: "http://127.0.0.1:8545/",
        //   initialBaseFeePerGas: 0,
        //   loggingEnabled: true,
        //   gasPrice: parseInt(gasPrice)
        // },
        // new_localhost: {
        //   chainId: 31337,
        //   url: "http://127.0.0.1:8545/",
        //   initialBaseFeePerGas: 0,
        //   loggingEnabled: true,
        //   // gasPrice: parseInt(gasPrice)
        // },
        // remain_localhost: {
        //     chainId: 44444,
        //     url: "http://localhost:8545",
        //     initialBaseFeePerGas: 0,
        //     loggingEnabled: true,
        //     type: "hardhat",
        //     gasPrice: parseInt(gasPrice)
        // },
        // Test Network
        // go: {
        //   chainId: 31337,
        //   url: "http://127.0.0.1:8545/",
        //   gasPrice: parseInt(gasPrice),
        //   initialBaseFeePerGas: 0,
        //   loggingEnabled: true,
        // },
        // baobab: {
        //   chainId: 31337,
        //   url: "http://127.0.0.1:8545/",
        //   gasPrice: parseInt(gasPrice),
        //   initialBaseFeePerGas: 0,
        //   loggingEnabled: true,
        // },
        // Main Network
    },
    settings: {
        optimizer: {
            enabled: true,
            runs: 1000,
        },
    },
};
