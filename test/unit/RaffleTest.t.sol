// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// This contract is a test for the Raffle contract
// The Raffle contract is a contract that allows participants to enter a raffle by paying a certain amount of ether
// The contract illustrates the use of vm.expectRevert, vm.expectEmit, vm.deal, vm.prank. 

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "lib/forge-std/src/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    /** Events */
    event EnteredRaffle(address indexed _participant);
    
    /** Modifiers */
    modifier raffleEnteredAndTimePassed() {
        raffle.enterRaffle{value: _ticketPrice}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }
    
    /** State Variables */
    Raffle raffle;
    HelperConfig helperConfig;
    //DeployRaffle deployRaffle;
    // Network Configurations
    uint256 _ticketPrice;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionID;
    uint32 callbackGasLimit;
    address link;
    //uint256 deployerKey;
    // Participant
    address public PARTICIPANT = makeAddr("participant");
    uint256 public constant STARTING_BALANCE = 10 ether; 

    /** functions */
    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle(); // deployRaffle is a contract instance of DeployRaffle
        (raffle, helperConfig) = deployRaffle.run(); // raffle and helperConfig are instances of Raffle and HelperConfig respectively
        (
        _ticketPrice, 
        interval, 
        vrfCoordinator, 
        gasLane, 
        subscriptionID, 
        callbackGasLimit,
        link
        ) = helperConfig.activeNetworkConfig(); // get the values of the activeNetworkConfig from the helperConfig contract
        vm.deal(PARTICIPANT, STARTING_BALANCE); // deal 10 ether to the participant
    }

    /**Test to see if the Raffle Initializes in Open State */
    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /**Enter Raffle Test: To see if the function reverts if the participant doesnt pay enough */

    function testEnterRaffleRevertsIfNotEnoughPaid() public {
        // Arrange
        vm.prank(PARTICIPANT); // prank the participant
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector); // expect the function to revert
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerEntry() public {
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value: _ticketPrice}();
        address participantRecorded = raffle.getParticipant(0);
        assert(participantRecorded == PARTICIPANT);
    }

    function testEventIsEmittedOnEntrance() public {
        // Arrange
        vm.prank(PARTICIPANT);
        // expect the event to be emitted. Arguments are (bool indexed, bool anonymous, bool emitted, bool notEmitted, address contract)
        // 1. declare the vm.expectEmit function specifying the arguments and the address of the contract
        vm.expectEmit(true, false, false, false, address(raffle));
        // Act / Assert 
        // 2. call the emit function
        emit EnteredRaffle(PARTICIPANT);
        // 3. call the function that emits the event
        raffle.enterRaffle{value: _ticketPrice}();
        
    }

    // The following tests simulates a player trying to enter the raffle when it is in a calculating winner state
    // First, the player enters the raffle
    // Then, the block timestamp is set such that enough time has passed for the raffle to calculate the winner
    // The block number is set
    // The raffle performs upkeep and calculates the winner
    // The player tries to enter the raffle again leading to a revert
    function testCantEnterWhenRaffleIsCalculatingWinner() public {
        // Arrange
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value: _ticketPrice}();
        // use vm.warp to set the block timestamp such that enough time has passed for the raffle to calculate the winner
        vm.warp(block.timestamp + interval + 1); 
        // use vm.roll to set the block number.
        vm.roll(block.number + 1);
        raffle.performUpkeep(""); // perform upkeep

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector); // expect the function to revert
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value: _ticketPrice}();
    }

    ////////////////////////
    // checkUpkeep Tests //
    ////////////////////////

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(upkeepNeeded == false); // assert(!upkeepNeeded);

    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        // Arrange
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value: _ticketPrice}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(upkeepNeeded == false); // assert(!upkeepNeeded)
    }

    // test to see if the checkUpkeep function returns false if enough time has not passed

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasNotPassed() public {
        // Arrange
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value: _ticketPrice}();
        vm.warp(block.timestamp + interval - 1);
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(upkeepNeeded == false); // assert(!upkeepNeeded)
    }

    // test to see if the checkUpkeep function returns true if all parameters are good

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        // Arrange
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value: _ticketPrice}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(upkeepNeeded == true); // assert(upkeepNeeded)
    }

     ////////////////////////
    // performUpkeep Tests //
    ////////////////////////

    // Test to see if performUpkeep only runs if checkUpkeep returns true

    function testPerformUpkeepOnlyRunsIfCheckUpkeepReturnsTrue() public {
        // Arrange
        vm.prank(PARTICIPANT);
        raffle.enterRaffle{value: _ticketPrice}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act / Assert
        raffle.performUpkeep("");
    }

    // Test to see if the performUpkeep function reverts if checkUpkeep returns false

    function testPerformUpkeepRevertsIfCheckUpkeepReturnsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numParticipants = 0;
        uint256 raffleState = 0;
        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance, 
                numParticipants, 
                raffleState)); // expect the function to revert

        raffle.performUpkeep("");

    }



    // test to see if performUpkeep updates the raffle state and emits a request id.ab

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEnteredAndTimePassed {
        // We need to capture the requestId emitted by the performUpkeep function
        // Act
        // recordLogs tells the vm to record the logs emitted by the performUpkeep function. 
        // The logs can be accessed using the getRecordedLogs function
        vm.recordLogs(); 
        raffle.performUpkeep(""); // emits the requestId
        Vm.Log[] memory entries = vm.getRecordedLogs(); // get the logs emitted by the performUpkeep function and stores them in the entries variable
        bytes32 requestId = entries[1].topics[1]; // get the requestId from the logs. See 6:10 in the video for more details. All logs are recorded as bytes32 in foundry.
        Raffle.RaffleState raffleState = raffle.getRaffleState(); // Creates an instance of the RaffleState enum in the Raffle contract and gets the current state of the raffle

        // Assert
        assert(uint256(requestId) > 0); 
        assert(uint256(raffleState) == 1); // assert(raffleState == Raffle.RaffleState.CALCULATING_WINNER);
       
    }

    // test to see if fulfill RandomWords can only be called after performUpkeep has been called.
    // this is a fuzz test that generates a random request id and tries to fulfill it without calling performUpkeep first
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public raffleEnteredAndTimePassed {
        // Arrange

        vm.expectRevert("nonexistent request"); // expect the function to revert
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    // test FulfillRandomWords Picks a winner, resets the raffle and sends money

    function testFulfillRandomWordsPicksWinnerResetsRaffleAndSendsMoney() public raffleEnteredAndTimePassed {
        // Arrange
        uint256 additionalParticipants = 5;
        uint256 startingIndex = 1;
        for (uint256 i = startingIndex; i < startingIndex + additionalParticipants; i++) {
           // vm.deal(makeAddr(i), _ticketPrice);
           // raffle.enterRaffle{value: _ticketPrice}();
           address participant = address(uint160(i)); // address participant = makeAddr(i);
           hoax(participant, STARTING_BALANCE); // sets up a prank and deals 1 ether to the participant
           raffle.enterRaffle{value: _ticketPrice}();
          
        }  
         uint256 prize = _ticketPrice * (additionalParticipants + 1);

        // Act
        // call perform upkeep to calculate the winner
        vm.recordLogs(); 
        raffle.performUpkeep(""); // emits the requestId
        Vm.Log[] memory entries = vm.getRecordedLogs(); 
        bytes32 requestId = entries[1].topics[1];

        uint256 previousTimestamp = raffle.getLastTimeStamp();

        // simulate chainlink VRF to get a random number and pick a winner
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));
        // Assert
        assert(uint256(raffle.getRaffleState()) == 0); // assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assert(raffle.getRecentWinner() != address(0)); 
        assert(raffle.getLengthOfParticipants() == 0); 
        assert(previousTimestamp < raffle.getLastTimeStamp());
        assert(raffle.getRecentWinner().balance == STARTING_BALANCE + prize - _ticketPrice);    
        
}



}