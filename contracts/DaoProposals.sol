// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
import "./DaoPermissionsInterface.sol";
import "./DaoUtils.sol";

/**
 *
* @notice This smart contract is responsible for the proposals of a DAO.
* The DAO must have as a base smart contract the LSP0ERC725Account.
 *
 * @author B00ste
 * @title DaoProposals
 * @custom:version 0.7
 */
contract DaoProposals {

  // --- GENERAL ATTRIBUTES

  /**
   * @notice Instance of the DAO key manager.
   */
  LSP0ERC725Account private DAO;

  /**
   * @notice Instance for the utils of a Universal Profile DAO.
   */
  DaoUtils private utils;

  /**
   * @notice Instance for the DAO permissions contract.
   */
  DaoPermissionsInterface private permissions;

  // --- PROPOSAL ATTRIBUTES

  /**
   * @notice Map data structure for fast access to the data of a proposal.
   */
  mapping(bytes32 => Proposal) private proposals;

  /**
   * @notice Percentage of pro votes needed for a proposal to pass.
   */
  uint8 private quorum;

  /**
   * @notice Participation rate needed to be reached for a proposal to be valid.
   */
  uint8 private participationRate;

  /**
   * @notice Time requiered to pass before ending the queueing period is possible.
   */
  uint256 private votingDelay;

  /**
   * @notice Time requiered to pass before ending the voting period is possible.
   */
  uint256 private votingPeriod;

  /**
   * @notice A struct containing all the info about a Proposal.
   */
  struct Proposal {
    string title;
    string description;
    address[] targets;
    bytes[] datas;
    /**
     * @notice Timestamps for each phase of a proposal.
     */
    uint256 creationTimestamp;
    uint256 votingTimestamp;
    uint256 endTimestamp;
    /**
     * @notice BitArray used for saving the current phase.
     * Phase 1 = 1
     * Phase 2 = 2
     * Phase 3 = 3
     */
    uint8 phase;
    /**
     * @notice Array for storing the 3 types of votes.
     * Index 0 are the against votes. 
     * Index 1 are the pro votes. 
     * Index 2 are the abstain votes. 
     */
    uint256[3] votes;

  } 
  
  /**
   * @notice Initializing the Proposals smart contract.
   */
  constructor(
    uint8 _quorum,
    uint8 _participationRate,
    uint256 _votingDelay,
    uint256 _votingPeriod,
    LSP0ERC725Account _DAO,
    DaoUtils _utils,
    address daoPermissions
  ) {
    require(_quorum >= 0 && _quorum <= 100);
    require(_participationRate >= 0 && _participationRate <= 100);
    quorum = _quorum;
    participationRate = _participationRate;
    votingDelay = _votingDelay;
    votingPeriod = _votingPeriod;
    DAO = _DAO;
    utils = _utils;
    permissions = DaoPermissionsInterface(daoPermissions);
  }

  // --- MODIFIERS

  /**
   * @notice Verify the phase that the proposal is in right now.
   */
  modifier checkPhase(bytes32 proposalSignature, uint8 _phase) {
    require(
      proposals[proposalSignature].phase == _phase,
      "The selected phase not reached yet."
    );
    _;
  }

  /**
   * @notice Verifies if an Universal Profile has VOTE permission.
   */
  modifier hasVotePermission(address universalProfileAddress) {
    bytes memory addressPermissions = permissions._getAddressDaoPermission(universalProfileAddress);
    require(
      (uint256(bytes32(addressPermissions)) & (1 << 0) == 1),
      "This address doesn't have VOTE permission."
    );
    _;
  }

  /**
   * @notice Verifies if an Universal Profile has PROPOSE permission.
   */
  modifier hasProposePermission(address universalProfileAddress) {
    bytes memory addressPermissions = permissions._getAddressDaoPermission(universalProfileAddress);
    require(
      (uint256(bytes32(addressPermissions)) & (1 << 1) == 2),
      "This address doesn't have PROPOSE permission."
    );
    _;
  }

  /**
   * @notice Verifys if total votes are enough for the proposal to pass. 
   */
  modifier checkVotes(bytes32 proposalSignature) {
    uint256[3] memory votes = proposals[proposalSignature].votes;
    require(
      votes[1]/(votes[1] + votes[0]) > quorum/(votes[1] + votes[0]),
      "Note enough pro votes for the proposal to pass."
    );
    require(
      (votes[1] + votes[0])/(votes[1] + votes[0] + votes[2]) > participationRate/(votes[1] + votes[0] + votes[2]),
      "Participation rate is too low for the proposal to pass."
    );
    _;
  }

  /**
   * @notice Verifying if the voting delay has passed. 
   */
  modifier votingDelayPassed(bytes32 proposalSignature) {
    require(
      votingDelay + proposals[proposalSignature].creationTimestamp < block.timestamp,
      "The voting delay is not yeat over."
    );
    _;
  }

  /**
   * @notice Verifying if the voting period has passed. 
   */
  modifier votingPeriodPassed(bytes32 proposalSignature) {
    require(
      votingPeriod + proposals[proposalSignature].votingTimestamp < block.timestamp,
      "The voting delay is not yeat over."
    );
    _;
  }

  /**
   * @notice Verifying if the voting period is still on.
   */
  modifier votingPeriodIsOn(bytes32 proposalSignature) {
    require(
      proposals[proposalSignature].votingTimestamp + votingPeriod > block.timestamp,
      "Voting period is already over."
    );
    _;
  }

  /**
   * @notice Verifying if universal profile is a participant of the DAO.
   */
  modifier isParticipantOfDao(address universalProfileAddress) {
    bytes memory addressPermissions = permissions._getAddressDaoPermission(universalProfileAddress);
    require(
      bytes32(addressPermissions) != bytes32(0),
      "This Universal Profile is not a participant of the DAO."
    );
    _;
  }

  // --- GETTERS & SETTERS

  /**
   * @notice Get the proposals array key depending on the phase of the proposals.
   */
  function getDaoProposalsArrayKeyByPhase(uint8 phaseNr) internal pure returns(bytes32 key) {
    bytes2 phase;
    if (phaseNr == 1) {
      phase = bytes2(keccak256("Phase1"));
    }
    else if(phaseNr == 2) {
      phase = bytes2(keccak256("Phase2"));
    }
    else if(phaseNr == 3) {
      phase = bytes2(keccak256("Phase3"));
    }
    key = bytes32(bytes.concat(
      phase,
      bytes8(keccak256("Proposals")),
      bytes20(keccak256("ProposalsArray[]"))
    ));
  }

  /**
   * @notice Get the proposals array lenngth.
   */
  function _getProposalsArrayLength(uint8 phaseNr) internal view returns(uint256 length) {
    length = uint256(bytes32(DAO.getData(getDaoProposalsArrayKeyByPhase(phaseNr))));
  }

  /**
   * @notice Set the proposals array lenngth.
   */
  function _setProposalsArrayLength(uint256 length, uint8 phaseNr) internal {
    bytes memory newLength = bytes.concat(bytes32(length));
    DAO.setData(getDaoProposalsArrayKeyByPhase(phaseNr), newLength);
  }

  /**
   * @notice Get Proposal by index.
   */
  function _getProposalByIndex(uint256 index, uint8 phaseNr) internal view returns(bytes memory proposalSignature) {
    bytes16[2] memory daoProposalsArrayKeyHalfs = utils._bytes32ToTwoHalfs(getDaoProposalsArrayKeyByPhase(phaseNr));
    bytes32 proposalKey = bytes32(bytes.concat(
      daoProposalsArrayKeyHalfs[0], bytes16(uint128(index))
    ));
    proposalSignature = DAO.getData(proposalKey);
  }

  /**
   * @notice Set Proposal by index.
   */
  function _setProposalByIndex(uint256 index, bytes32 _proposalSignature, uint8 phaseNr) internal {
    bytes16[2] memory daoProposalsArrayKeyHalfs = utils._bytes32ToTwoHalfs(getDaoProposalsArrayKeyByPhase(phaseNr));
    bytes32 proposalKey = bytes32(bytes.concat(
      daoProposalsArrayKeyHalfs[0], bytes16(uint128(index))
    ));
    bytes memory proposalSignature = bytes.concat(_proposalSignature);
    DAO.setData(proposalKey, proposalSignature);
  }

  /**
   * @notice Remove Proposal by index.
   */
  function _removeProposal(bytes32 proposalSignature, uint8 phaseNr) internal returns(bool, bytes32) {
    uint256 length = _getProposalsArrayLength(phaseNr);
    for (uint i = 0; i < length; i++) {
      bytes32 currentProposalSignature = bytes23(_getProposalByIndex(i, phaseNr));
      bytes32 nextProposalSignature = bytes32(_getProposalByIndex((i + 1), phaseNr));
      if (currentProposalSignature == proposalSignature) {
        _setProposalByIndex(i, nextProposalSignature, phaseNr);
        _setProposalByIndex((i + 1), currentProposalSignature, phaseNr);
      }
    }
    _setProposalByIndex(length, bytes32(0), phaseNr);
    _setProposalsArrayLength((length + 1), phaseNr);
    return (true, proposalSignature);
  }

  /**
   * @notice Get DAO proposal data.
   */
  function _getProposalData(bytes32 proposalSignature) internal view returns(
      string memory title,
      string memory description,
      uint256 creationTimestamp,
      uint256 votingTimestamp,
      uint256 endTimestamp,
      uint256 againstVotes,
      uint256 proVotes,
      uint256 abstainVotes
  ) {
    (
      title,
      description,
      creationTimestamp,
      votingTimestamp,
      endTimestamp,
      againstVotes,
      proVotes,
      abstainVotes
    ) = abi.decode(DAO.getData(proposalSignature), (string, string, uint256, uint256, uint256, uint256, uint256, uint256));
  }

  /**
   * @notice Set DAO proposal data.
   */
  function _setProposalData(bytes32 proposalSignature, bytes memory proposalData) internal {
    DAO.setData(
      proposalSignature,
      proposalData  
    );
  }

  // --- INTERNAL METHODS

  /**
   * @notice Saves a ended proposal to the UniversalProfile.
   */
  function saveProposal(bytes32 proposalSignature, uint8 phaseNr) private {

    uint256 proposalsArrayLength = _getProposalsArrayLength(phaseNr);
    bytes memory proposalDataBytes = abi.encode(
        proposals[proposalSignature].title,
        proposals[proposalSignature].description,
        proposals[proposalSignature].creationTimestamp,
        proposals[proposalSignature].votingTimestamp,
        proposals[proposalSignature].endTimestamp,
        proposals[proposalSignature].votes[0],
        proposals[proposalSignature].votes[1],
        proposals[proposalSignature].votes[2]
    );

    _setProposalByIndex(proposalsArrayLength, proposalSignature, phaseNr);
    _setProposalsArrayLength(proposalsArrayLength + 1, phaseNr);
    _setProposalData(proposalSignature, proposalDataBytes);
    
  }

  // --- GENERAL METHODS

  /**
   * @notice Create a proposal.
   * The proposal signature is encoded to a bytes32 variable using
   * abi.encode(_title, _description, _targets, _datas).
   *
   * @param _title Title of the proposal.
   * @param _description Description of the proposal.
   * @param _targets The addresses of the smart contracts that might have calldata executed.
   * @param _datas The calldata that will be executed if the proposall passes.
   */
  function createProposal(
    string memory _title,
    string memory _description,
    address[] memory _targets,
    bytes[] memory _datas
  )
    external
    hasProposePermission(msg.sender)
    returns(bytes32 proposalSignature)
  {
    require(_targets.length == _datas.length, "Provided targets and datas have different lengths.");

    proposalSignature = bytes32(keccak256(
      abi.encode(
        _title,
        _description,
        block.timestamp
    )));

    proposals[proposalSignature].title = _title;
    proposals[proposalSignature].description = _description;
    proposals[proposalSignature].targets = _targets;
    proposals[proposalSignature].datas = _datas;
    proposals[proposalSignature].phase = 1;
    proposals[proposalSignature].creationTimestamp = block.timestamp;

    saveProposal(proposalSignature, 1);
  }

  /**
   * @notice Move the proposal to the voting phase.
   *
   * @param proposalSignature The abi.encode bytes32 signature of a proposal.
   */
  function putProposalToVote(
    bytes32 proposalSignature
  ) 
    external
    checkPhase(proposalSignature, (1 << 0))
    votingDelayPassed(proposalSignature)
    isParticipantOfDao(msg.sender)
  {
    proposals[proposalSignature].phase = 2;
    proposals[proposalSignature].votingTimestamp = block.timestamp;
    saveProposal(proposalSignature, 2);
    _removeProposal(proposalSignature, 1);
  }

  /**
   * @notice End proposal and execute the calldata.
   * Encode the proposal info, timestamps and results and save them to the Universal Profile of the DAO.
   *
   * @param proposalSignature The abi.encode bytes32 signature of a proposal.
   */
  function endProposal(
    bytes32 proposalSignature
  ) 
    external
    checkPhase(proposalSignature, (1 << 1))
    checkVotes(proposalSignature)
    votingPeriodPassed(proposalSignature)
    isParticipantOfDao(msg.sender)
  {
    proposals[proposalSignature].phase = 3;
    proposals[proposalSignature].endTimestamp = block.timestamp;
    for (uint i = 0; i < proposals[proposalSignature].targets.length; i++) {
      DAO.execute(
        0,
        proposals[proposalSignature].targets[i],
        0,
        proposals[proposalSignature].datas[i]
      );
    }

    saveProposal(proposalSignature, 3);
    _removeProposal(proposalSignature, 2);
    delete proposals[proposalSignature];
  }

  /**
   * @notice Vote on a proposal.
   *
   * @param proposalSignature The abi.encode bytes32 signature of a proposal.
   * @param voteIndex a number 0 <= `voteIndex` <= 2.
   * Index 0 are the against votes. 
   * Index 1 are the pro votes. 
   * Index 2 are the abstain votes. 
   */
  function vote(
    bytes32 proposalSignature,
    uint8 voteIndex
  )
    external
    checkPhase(proposalSignature, (1 << 1))
    hasVotePermission(msg.sender)
    votingPeriodIsOn(proposalSignature)
  {
    proposals[proposalSignature].votes[voteIndex] ++;
  }

}