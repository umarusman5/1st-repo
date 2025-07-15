// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// When a functionality can be _commonly used_, we can create a **library** to efficiently manage repeated parts of codes.
// Solidity libraries are similar to contracts but do not allow the declaration of any **state variables** and **cannot receive ETH**.
// All functions in a library must be declared as `internal` and are embedded in the contract during compilation. If any function is not marked as such, the library cannot be embedded directly, but it must be deployed independently and then linked to the main contract.

// This will actually get the code from github
// AggregatorV3Interface` is a contract that takes a _Data Feed address_ as input. This contract maintains the ETH/USD price updated.
// Price Feed interface, called `Aggregator V3 Interface` would return the ABI of the Price Feed contract itself, which was previously deployed on the blockchain. We don't need to know anything about the function implementations, only knowing the `AggregatorV3Interface` methods will suffice.
// **Interface** defines methods signature without their implementation logic
// A method signature (or function signature) is a unique identifier for a function within a contract. It combines the function's name and the data types of its input parameters, forming a string used to differentiate it from other functions
// Remix interprets `@chainlink/contracts` as a reference to the [NPM package], and downloads all the necessary code from it.

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface pricefeed
    ) internal view returns (uint256) {
        // Address 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // ABI
        // The code below is inspired from the code on chainlink's website
        (, int256 price, , , ) = pricefeed.latestRoundData(); // Price is int256 because it can be negative
        // Price of ETH in terms of USD = 2500*10**8
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 AmountofETH,
        AggregatorV3Interface pricefeed
    ) internal view returns (uint256) {
        // In this function we will get the total price of ETH according to the quantity the user sends
        uint256 ethPrice = getPrice(pricefeed);
        uint256 ethAmount = AmountofETH;
        // Amounts of eth are send in terms of wei and we know that 1ETH = 1e18 wei, so we will multiply two e18 and we will get e36
        uint256 Price = (ethPrice * ethAmount) / (1e36);
        return Price;
    }
}
