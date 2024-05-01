// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Interactions.s.sol
 * @dev This contract is a script that creates a subscription using the VRFCoordinatorV2Mock contract
 * Interactions are performed in the following order:
 * 1. The run function calls the createSubscriptionUsingConfig function
 * 2. The createSubscriptionUsingConfig function gets the vrfCoordinator address from the HelperConfig contract and calls the createSubscription function
 * 3. The createSubscription function calls the VRFCoordinatorV2Mock contract to create a subscription and returns the subscription ID
 */

import {Script, console} from "lib/forge-std/src/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";


contract CreateSubscription is Script {
    // Initialiyation: This function fetches environment specific variables from the HelperConfig contract and calls the createSubscription function
    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , ,) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    // Action Definition: This function creates a subscription using the VRFCoordinatorV2Mock contract. It returns the subscription ID
    function createSubscription(address vrfCoordinator) public returns (uint64) {
        console.log("Creating a subscription on ChainId: ", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your Subscription ID is: ", subId);
        console.log("Remember to update subscriptionID in the HelperConfig contract");
        return subId;
    }
    // This is the entry point of the script
    function run() external returns  (uint64) {
        return createSubscriptionUsingConfig();
    }

} 

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , uint64 subID,, address link) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subID, link);  
    }

    function fundSubscription(address vrfCoordinator, uint64 subID, address link) public {
        console.log("Funding subscription:", subID, "with LINK");
        console.log("Using vrfCoordinator:", vrfCoordinator);
        console.log("On ChainId:", block.chainid);
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subID, FUND_AMOUNT);
            vm.stopBroadcast();   
         } else {
        vm.startBroadcast();
        LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subID));
        vm.stopBroadcast();
    }
    
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }

}


contract AddConsumer is Script {
   // address raffle;

    function addConsumer(address raffle, address vrfCoordinator, uint64 subID) public {
        console.log("Adding consumer to Raffle contract", raffle);
        console.log("Using vrfCoordinator:", vrfCoordinator);
        console.log("On ChainId:", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subID, raffle);
        vm.stopBroadcast();
    }
    
    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , uint64 subID, ,) = helperConfig.activeNetworkConfig();
        addConsumer(raffle, vrfCoordinator, subID);
    }
    
    
    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);

        addConsumerUsingConfig(raffle);
    }


}