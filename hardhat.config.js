// JS
const path = require("path");

require("@nomicfoundation/hardhat-chai-matchers");
require("@nomicfoundation/hardhat-verify");
require("hardhat-contract-sizer");

// process.env
require("dotenv").config({ path: path.resolve(__dirname, "./.env") });

const optimizerSettings = {
    enabled: true,
    runs: 1000000,
    details: {
        // The peephole optimizer is always on if no details are given,
        // use details to switch it off.
        peephole: true,
        // The inliner is always on if no details are given,
        // use details to switch it off.
        inliner: true,
        // The unused jumpdest remover is always on if no details are given,
        // use details to switch it off.
        jumpdestRemover: true,
        // Sometimes re-orders literals in commutative operations.
        orderLiterals: true,
        // Removes duplicate code blocks
        deduplicate: true,
        // Common subexpression elimination, this is the most complicated step but
        // can also provide the largest gain.
        cse: true,
        // Optimize representation of literal numbers and strings in code.
        constantOptimizer: true,
        yulDetails: {
            stackAllocation: true,
            optimizerSteps: "dhfoDgvulfnTUtnIf[xa[r]EscLMcCTUtTOntnfDIulLculVcul[j]Tpeulxa[rul]xa[r]cLgvifCTUca[r]LSsTOtfDnca[r]Iulc]jmul[jul]VcTOculjmul",
        },
    },
};

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: {
        compilers: [
            {
                version: "0.8.17",
                settings: {
                    viaIR: true,
                    optimizer: {
                        ...optimizerSettings,
                    },
                    metadata: {
                        bytecodeHash: "none",
                    },
                },
            },
        ],
    },
    defaultNetwork: "localhost",
    networks: {
        // Local
        localhost: {
            url: "http://127.0.0.1:8545/",
            chainId: 31337,
            timeout: 400000000,
        },
        // Mainnet
        mainnet: {
            url: process.env.RPC_URL_MAINNET,
            chainId: 1,
            accounts: [process.env.CYGNUS_DEPLOYER],
        },
        // Arbitrum
        arbitrum: {
            url: process.env.RPC_URL_ARBITRUM,
            chainId: 42161,
            accounts: [process.env.CYGNUS_DEPLOYER],
        },
        // Polygon
        polygon: {
            url: process.env.RPC_URL_POLYGON,
            chainId: 137,
            accounts: [process.env.CYGNUS_DEPLOYER],
        },
        // Polygon testnet
        polygonMumbai: {
            url: process.env.RPC_URL_POLYGON_TESTNET,
            chainId: 80001,
            accounts: [process.env.CYGNUS_DEPLOYER],
        },
        // Optimism
        optimism: {
            url: process.env.RPC_URL_OPTIMISM,
            chainId: 10,
            accounts: [process.env.CYGNUS_DEPLOYER],
        },
        optimismGoerli: {
            url: process.env.RPC_URL_OPTIMISM_GOERLI,
            chainId: 420,
            accounts: [process.env.CYGNUS_DEPLOYER],
        },
        bsc: {
            url: "https://rpc.ankr.com/bsc",
            chainId: 56,
        },
        devnet: {
            url: "https://rpc.vnet.tenderly.co/devnet/polygon/179f5f2d-733f-448d-997f-e4a2dfc0b63e",
            chainId: 137,
        },
        zkevm: {
            url: process.env.RPC_URL_ZKEVM,
            chainId: 1101,
            accounts: [process.env.CYGNUS_DEPLOYER],
        },
        zkevmTestnet: {
            url: "https://rpc.ankr.com/polygon_zkevm_testnet",
            chainId: 1442,
            accounts: [process.env.CYGNUS_DEPLOYER],
        },
    },
    mocha: { timeout: 100000000 },
    etherscan: {
        apiKey: {
            mainnet: process.env.ETHERSCAN_KEY_MAINNET,
            optimisticEthereum: process.env.ETHERSCAN_KEY_OPTIMISM,
            arbitrumOne: process.env.ETHERSCAN_KEY_ARBITRUM,
            polygonMumbai: process.env.ETHERSCAN_KEY_POLYGON,
            polygon: process.env.ETHERSCAN_KEY_POLYGON,
            zkevm: process.env.ETHERSCAN_KEY_ZKEVM,
            zkevmTestnet: process.env.ETHERSCAN_KEY_ZKEVM,
        },
        customChains: [
            {
                network: "zkevm",
                chainId: 1101,
                urls: {
                    apiURL: "https://api-zkevm.polygonscan.com/",
                    browserURL: "https://zkevm.polygonscan.com/",
                },
            },
            {
                network: "zkevmTestnet",
                chainId: 1442,
                urls: {
                    apiURL: "https://api-testnet-zkevm.polygonscan.com/",
                    browserURL: "https://testnet-zkevm.polygonscan.com/",
                },
            },
        ],
    },
};
