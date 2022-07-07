// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@lukso/lsp-smart-contracts/contracts/LSP7DigitalAsset/ILSP7DigitalAsset.sol";

contract Proposal {

  /**
   * @notice Defining the BitMaps.
   */
  using BitMaps for BitMaps.BitMap;

  // --- ATTRIBUTES

  /**
   * @notice Proposal title.
   */
  bytes private title;

  /**
   * @notice Proposal describtion.
   */
  bytes private description;

  /**
   * @notice Percentage of total possible votes necessary for a proposal vote to be valid.
   */
  uint256 private percentageOfVotesToPass;

  /**
   * @notice Percentage of pro votes for a proposal to pass.
   */
  uint256 private percentaceOfForVotesToPass;

  /**
   * @notice Votes of the proposal.
   * `votes[0]` refers to the against votes.
   * `votes[1]` refers to pro votes.
   * `votes[2]` refers to abstain votes.
   */
  uint256[3] private votes;

  /**
   * @notice Targets for calldata of a proposal.
   */
  address[] private targets;

  /**
   * @notice Data to be executed after a proposal passed.
   */
  bytes[] private datas;

  /**
   * @notice Using a BitMap for the phases of a proposal.
   * Phase 0 refers to the time between the creation of a proposal and the voting on that proposal.
   * Phase 1 refers to the time between the voting period and the end of a proposal.
   * Phase 2 is the final phase, when the reuslts are definite.
   */
  BitMaps.BitMap phases;

  /**
   * @notice Timestamp of the start of phase 0.
   */
  uint256 phase0StartingTime;

  /**
   * @notice Timestamp of the start of phase 1.
   */
  uint256 phase1StartingTime;

  /**
   * @notice Timestamp of the start of phase 2.
   */
  uint256 phase2StartingTime;

  /**
   * @notice Time requiered to pass before moving from phase 0 to phase 1.
   */
  uint256 timeBetweenPhase0and1;

  /**
   * @notice Time requiered to pass before moving from phase 1 to phase 2.
   */
  uint256 timeBetweenPhase1and2;

  /**
   * @notice An intance of the token needed to be holded in order to vote.
   */
  ILSP7DigitalAsset token;

  /**
   * @notice Initializing the necessary attributes for creating a proposal.
   */
  constructor(
    string memory _title,
    string memory _description,
    uint256 _percentageOfVotesToPass,
    uint256 _percentaceOfForVotesToPass,
    address[] memory _targets,
    bytes[] memory _datas,
    uint256 _timeBetweenPhase0and1,
    uint256 _timeBetweenPhase1and2,
    address _tokenAddress
  ) {
    title = abi.encodePacked(_title);
    description = abi.encodePacked(_description);
    percentageOfVotesToPass = _percentageOfVotesToPass;
    percentaceOfForVotesToPass = _percentaceOfForVotesToPass;
    targets = _targets;
    datas = _datas;
    phases.set(0);
    phase0StartingTime = block.timestamp;
    timeBetweenPhase0and1 = _timeBetweenPhase0and1;
    timeBetweenPhase1and2 = _timeBetweenPhase1and2;
    token = ILSP7DigitalAsset(_tokenAddress);
  }

  // --- MODIFIERS

  /**
   * @notice Verifies if the the last phase is active in order to move to the next phase.
   */
  modifier requirePhase(uint index) {
    require(
      phases.get(index),
      "Phase not yet reached."
    );
    _;
  }

  /**
   * @notice Verifies if the proposal has enough pro votes to pass.
   */
  modifier enoughProVotes() {
    require(
      votes[1]/(votes[0] + votes[1]) > percentaceOfForVotesToPass/100,
      "The proposal didn't recieve enough pro votes."
    );
    _;
  }

  /**
   * @notice Verifies if the proposal has enough pro or against activity to pass.
   */
  modifier enoughTotalVotes() {
    require(
      (votes[0] + votes[1])/(votes[0] + votes[1] + votes[2]) > percentageOfVotesToPass/100,
      "The proposal didn't have enough total votes."
    );
    _;
  }

  /**
   * @notice Verifies if the period in phase 0 is over.
   */
  modifier phase0TimePassed() {
    require(
      phase0StartingTime + timeBetweenPhase0and1 < block.timestamp,
      "Phase 0 is not over yet."
    );
    _;
  }

  /**
   * @notice Verifies if the period in phase 1 is over.
   */
  modifier phase1TimePassed() {
    require(
      phase1StartingTime + timeBetweenPhase1and2 < block.timestamp,
      "Phase 1 is not over yet."
    );
    _;
  }

  /**
   * @notice Verify if the number is >= 0 and <= 2
   */
  modifier checkIndex(uint8 index) {
    require(
      index >= 0 && index <= 2,
      "The index is bigger than 2 or smaller than 0"
    );
    _;
  }

  // --- EVENTS

  event ExecutionResult(bool success, bytes result);

  // --- GENERAL METHODS

  /**
   * @notice Start the voting phase of a proposal.
   */
  function _startProposal() internal requirePhase(0) phase0TimePassed {
    phases.set(1);
    phase1StartingTime = block.timestamp;
    votes[2] = token.totalSupply();
  }

  /**
   * @notice Vote.
   */
  function _vote(uint8 index) internal requirePhase(1) checkIndex(index) {
    if (index != 2) {
      votes[index] += token.balanceOf(msg.sender);
      votes[2] -= token.balanceOf(msg.sender);
    }
  }

  /**
   * @notice End a proposal and execute depending on results.
   */
  function _endProposal()
    internal
    requirePhase(1)
    phase1TimePassed
    enoughTotalVotes
    enoughProVotes
  {
    for(uint i = 0; i < targets.length; i++) {
      (bool success, bytes memory result) = targets[i].call(datas[i]);
      require(success, "Call failed");
      emit ExecutionResult(success, result);
    }
    phases.set(2);
    phase2StartingTime = block.timestamp;
  }

}