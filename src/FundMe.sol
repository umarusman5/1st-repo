// Get funds from users
// Withdraw Funds
// Set a minimum funding value in usd

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {PriceConverter} from "../src/PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    // The line below attaches the functions in our PriceConverter library to all uint256s
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5; // constant keyword saves gas as we aren't going to change the value of MINIMUM_USD, and this is convention of naming constants

    address[] private s_funders; // Private variables are more gas efficient than public variables

    /*s_ prefix is used to indicate that this variable is a state variable, which means it is stored
     on the blockchain and its value persists between function calls*/

    mapping(address => uint256) private s_addressToAmountFunded;

    // we are setting it immutable and not constant because we are assign its value inside another function
    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed; // private means that this variable can only be accessed from within this contract

    constructor(address priceFeed) {
        // Constructor is a special function, which is immediately called when this contract is deployed for the first time.
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // Payable is the keyword for making our fund() function accept funds
        // Allow users to send $
        // Have a minimum $ spent
        // The Solidity global property msg.value contains the amount of cryptocurrency sent with a transaction.
        //require(getConversionRate(msg.value) >= minimumUSD, "Didn't send enough Ether"); // 1e18 = 1 ETH = 1*10**18 Wei = 1*e**9 Gwei
        // The `PriceConverter` functions can be called as if they are native to the `uint256` type. For example, calling the `getConversionRate()` function will now be changed into:
        // `msg.value`, which is a `uint256` type, is extended to include the `getConversionRate()` function. The `msg.value` gets passed as the first argument to the function. If additional arguments are needed, they are passed in parentheses

        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Didn't send enough Ether");
        s_funders.push(msg.sender); // The `msg.sender` global variable refers to the address that **initiates the transaction**.
        // addresstoamount[msg.sender] = addresstoamount[msg.sender] + msg.value;
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    // When you call getVersion(), it returns this integer value so that your smart contracts can be aware of which protocol release they're interacting with.
    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not the owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; //  First execute the required condition and then the code that is in the function with which this modifier is used
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length; // We will call from memory instead of storage to save gas
        for (uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0; // Reset the amount funded
        }
        s_funders = new address[](0); // Reset the array of funders to an empty array
        (bool CallSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(CallSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0); // new address[]: Creates an empty array of type "address" (essentially like [...]). (0): Initializes the newly created array with zero length. When you want to remove all elements from an array (like deleting every item), but still keep its type as an array (address[]) for future use or other functions' compatibility reasons.
        (bool CallSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(CallSuccess, "Call failed");
    }

    // The receive function is specifically designed to handle Ether transfers without data and is automatically invoked when Ether. The fallback function is used for handling calls with data or when the receive function is not defined. The fallback function can also handle Ether transfers with data.
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /*
    View/Pure functions (Getters)*/

    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        // This function is a getter function that returns the amount funded by a specific address
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        // This function is a getter function that returns the address of a specific funder
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        // This function is a getter function that returns the owner of the contract
        return i_owner;
    }
}
// Internal function or variable can be accessed inside the contract where it is defined and in derived (child) contracts.
// Private function or variable can only be accessed inside the contract where it is defined.
// Public function or variable can be accessed from anywhere, including other contracts and transactions.
// External function can only be called from outside the contract, not from within the contract itself. It is typically used for functions that are meant to be called by other contracts or users.
// View functions are read-only functions that do not modify the state of the contract. They can be called without sending a transaction and do not consume gas.
// Pure functions are similar to view functions, but they do not read or modify the state of the contract. They are used for calculations that do not depend on the contract's state.
