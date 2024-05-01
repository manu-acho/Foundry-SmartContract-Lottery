// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

// lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol

contract HelperConfig is Script {
    /**Type Declarations */
    struct NetworkConfig {
        uint256 _ticketPrice;
        uint256 interval;
        address vrfCoordinator; 
        bytes32 gasLane;
        uint64 subscriptionID; 
        uint32 callbackGasLimit;
        address link;
        
    }
    /** Variables */
    NetworkConfig public activeNetworkConfig;
    //uint256 public constant DEFAULT_ANVIL_DEPLOYER_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
   // uint256 public constant DEFAULT_ANVIL_DEPLOYER_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    /** Functions */

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory) {
        return NetworkConfig({
            _ticketPrice: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionID: 9930, // 9930
            callbackGasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
          
        });
    }

    function getOrCreateAnvilEthConfig() public  returns(NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }
        // The constructor of VRFCoordinatorV2Mock takes two arguments: baseFee and gasPriceLink
        uint96 baseFee = 0.25 ether; // 0.25 LINK
        uint96 gasPriceLink = 1e9; // 1 Gwei LINK

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
        vm.stopBroadcast();
        LinkToken link = new LinkToken();

        return NetworkConfig({
            _ticketPrice: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionID: 0,
            callbackGasLimit: 500000,
            link: address(link)
            
           
        });
        

    }


}






 
