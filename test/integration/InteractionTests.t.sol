// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user"); // This creates a new address with the name "user" for testing purposes (foundry cheatcode)

    uint256 constant SEND_VALUE = 0.1 ether; // This is the amount of ETH we will send to the fund function
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

    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);
    }
}
