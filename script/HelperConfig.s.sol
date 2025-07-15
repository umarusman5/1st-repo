// SPDX-License-Identifier: MIT

// 1. Deploy Mocks when we are on a local anvil chain
// 2. Keep track of contract address across different chains
// Sepolia ETH/USD
// Mainnet ETH/USD
// Because of this contract we will not require to hardcore the address

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MocksV3Aggregator.sol";
pragma solidity ^0.8.25;

contract HelperConfig is Script {
    // If we are on a local anvil, we deploy mocks
    // Otherwise, grab the existing address from the live network

    /* We need to separate the struct definition from the state variable declaration, as Solidity does not allow visibility specifiers
     on struct definitions. */

    struct NetworkConfig {
        address priceFeed;
    }

    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    constructor() {
        if (block.chainid == 11155111) {
            // block.chainid is a global variable that returns the chain ID of the current network
            // Sepolia
            activeNetworkConfig = getSepoliaETHConfig();
        } else {
            // Anvil
            activeNetworkConfig = getorCreateAnvilETHConfig();
        }
    }

    function getSepoliaETHConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306 // Sepolia ETH/USD Price Feed
        });
        return sepoliaConfig;
    }

    function getorCreateAnvilETHConfig() public returns (NetworkConfig memory) {
        /* If we run getorCreatrAnvilETHConfig without the lines below we will end up creating a new PriceFeed (check if we already 
        deployed the mockPriceFeed before deploying it once more.) */

        if (activeNetworkConfig.priceFeed != address(0)) {
            // Address defaults to 0x0
            // If the price feed is already set, return the existing config
            return activeNetworkConfig;
        }

        // 1. Deploy the mock contract
        // 2. Return the mock address

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        ); // 2000 USD in 8 decimals
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed) // The address of the deployed mock contract
        });
        return anvilConfig;
    }
}
