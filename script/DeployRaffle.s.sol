// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import {Script} from "lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    /**
     * This function retrieves the active network config and checks if a subscription exists and if not creates one
     * It then funds the subscription and creates a new Raffle contract
     * Finally it adds the Raffle contract as a VRF consumer
     */
    
    function run() external returns(Raffle, HelperConfig) {
    
        HelperConfig helperConfig = new HelperConfig();
        (
        uint256 _ticketPrice, 
        uint256 interval, 
        address vrfCoordinator, 
        bytes32 gasLane, 
        uint64 subscriptionID, 
        uint32 callbackGasLimit,
        address link
        ) = helperConfig.activeNetworkConfig(); 


        // This is equivalent to "NetworkConfig memory activeNetworkConfig = helperConfig.activeNetworkConfig();""
       // However the Network config is a struct that is not inherited from the HelperConfig contract

        if(subscriptionID == 0) {
            // We need to create a subscription
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionID = createSubscription.createSubscription(vrfCoordinator);

            // We need to fund the subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinator, subscriptionID, link);


        }
       
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            _ticketPrice, 
            interval, 
            vrfCoordinator, 
            gasLane, 
            subscriptionID, 
            callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), vrfCoordinator, subscriptionID);       //
        return (raffle, helperConfig);
    }

}


