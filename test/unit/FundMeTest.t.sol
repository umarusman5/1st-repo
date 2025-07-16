// SPDX-License-Identifier: MIT
// This file contains the tests for the FundMe contract.
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

//Inheritance
contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user"); // This creates a new address with the name "user" for testing purposes (foundry cheatcode)

    uint256 constant SEND_VALUE = 5 ether; // This is the amount of ETH we will send to the fund function
    uint256 constant STARTING_BALANCE = 50 ether; // This is the starting balance of the USER address

    // Eveytime we call a test function we also call the setUp function
    // setUp is a special function in Foundry that runs before each test function
    // It is used to set up the initial state of the contract before each test

    function setUp() public {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // This gives the USER address a starting balance of 50 ETH
            // vm.deal() is a Foundry cheatcode that allows you to set the balance
    }

    function testMINIMUMUSDisFive() public view {
        /* Adding view removes the warning and makes your intent explicit. If you omit it, the compiler warns you that the function
         could be marked as view for better code quality.*/
        // This test checks if the constant MINIMUM_USD is set to 5
        assertEq(fundMe.MINIMUM_USD(), 5);
    }

    function testOwnerisMsgSender() public view {
        /* We do not need console.log("The owner is:", fundMe.i_owner()); console.log(msg.sender); to check the error in this case 
        as without these, we will still get the addresses that are not matching*/

        // This test checks if the owner of the contract is the address that deployed it
        // We call FundMeTest and FundMeTest calls the FundMe contract
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4, "The price feed version is not accurate");
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert("Didn't send enough Ether"); // Hey! the next line should revert with this error message
        fundMe.fund(); // This line should revert because we are sending 0 ETH
    }

    modifier funded() {
        vm.prank(USER); // The next TX will be sent by USER
        fundMe.fund{value: SEND_VALUE}(); // We are sending 5 ETH to the fund function
        _; //  First execute the required code in the modifier and then the code that is in the function with which this modifier is used
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER); // We are getting the amount funded by the msg.sender
        assertEq(amountFunded, SEND_VALUE, "The amount funded is not correct");
    }

    function testAddFunderstoArrayofFunders() public funded {
        // This tests the getFunder function
        address funder = fundMe.getFunder(0); // We are getting the first funder from the array of funders
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER); // We are pretending that the next transaction is sent by USER (it ignores the vm line)

        // vm.expectRevert(FundMe__NotOwner.selector);
        // fundMe.withdraw(); This tells Foundry to expect a revert with the custom error FundMe__NotOwner, not a string-based revert.

        vm.expectRevert(); // Hey! the next line should revert
        fundMe.withdraw(); // This line will not revert because USER the owner
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange (Arrange/Set up the test)
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // Get the starting balance of the owner
        uint256 startingFundMeBalance = address(fundMe).balance; // Get the starting balance of the FundMe contract

        // Act (Action I actually want to test)
        vm.prank(fundMe.getOwner()); // The next TX will be sent by the owner
        fundMe.withdraw(); // The owner withdraws the funds

        // Assert (Assert the expected outcome)
        uint256 endingOwnerBalance = fundMe.getOwner().balance; // Get the ending balance of the owner
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
    }

    function testWithdrawWithMultipleFunders() public {
        // Arrange
        // We use uint160 to create multiple addresses for testing purposes

        uint160 numberOfFunders = 10; // We will add 10 funders
        uint160 startingIndex = 1; // We will start from index 1
        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); //It is a Foundry cheatcode that: 1) Sets the next transaction to be sent from address(i).
            //2) Gives address(i) a balance of SEND_VALUE (e.g., 5 ether)

            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // Act
        vm.startPrank(fundMe.getOwner()); // The next TX will be sent by the owner
        fundMe.withdraw(); // The owner withdraws the funds
        vm.stopPrank(); // Stop the prank, so the next TX will be sent by the original sender

        // Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);
    }

    function testWithdrawWithMultipleFundersCheaper() public {
        // Arrange
        // We use uint160 to create multiple addresses for testing purposes

        uint160 numberOfFunders = 10; // We will add 10 funders
        uint160 startingIndex = 1; // We will start from index 1
        for (uint160 i = startingIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); //It is a Foundry cheatcode that: 1) Sets the next transaction to be sent from address(i).
            //2) Gives address(i) a balance of SEND_VALUE (e.g., 5 ether)

            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // Act
        vm.startPrank(fundMe.getOwner()); // The next TX will be sent by the owner
        fundMe.cheaperWithdraw(); // The owner withdraws the funds
        vm.stopPrank(); // Stop the prank, so the next TX will be sent by the original sender

        // Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);
    }
}

/*In the context of your Solidity tests with Foundry, log refers to printing information to the terminal
using the console object. For example, console.log() lets you output values (like variables or addresses)
during test execution. This is useful for debugging and understanding what your contract or test is
doing at specific points.*/
