// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // The reason we are using the HelperConfig is to get the price feed address
        /* The reason we are declaring helperConfig outside of the vm.startBroadcast() is to save gas, so that we dont spend gas
         to deploy this on a real chain */
        // Before startBroadcast -> not a real transaction (it will simulate on a simulation environment)
        HelperConfig helperConfig = new HelperConfig();
        address ethUSDPriceFeed = helperConfig.activeNetworkConfig();

        // Start the script with the default private key
        vm.startBroadcast();

        // Deploy the FundMe contract
        FundMe fundMe = new FundMe(ethUSDPriceFeed); // 0x694AA1769357215DE4FAC081bf1f309aDC325306 // Sepolia ETH/USD Price Feed

        // Stop the script
        vm.stopBroadcast();

        return fundMe;
    }
}

/*When a smart contract's constructor assigns `msg.sender` to a state variable (e.g., `owner`), and this contract is deployed
via a script called from a test that uses a broadcast mechanism (like Foundry's `vm.startBroadcast`), what address is typically assigned?*/
// The default deployer/sender account configured in the testing or scripting environment.
// Forking tests is type of testing involves creating a copy of a blockchain's state at a specific point in time to run simulations
