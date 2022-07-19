// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
import "./Interfaces/DaoPermissionsInterface.sol";
import "./Interfaces/DaoDelegatesInterface.sol";
import "./Interfaces/DaoAccountMetadataInterface.sol";
import "./DaoUtils.sol";

/**
 *
* @notice This smart contract is responsible for the proposals of a DAO.
* The DAO must have as a base smart contract the LSP0ERC725Account.
 *
 * @author B00ste
 * @title DaoProposals
 * @custom:version 0.9
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

  /**
   * @notice Instance for the DAO delegates.
   */
  DaoDelegatesInterface private delegates;

  /**
   * @notice Instance for the DAO metadata.
   */
  DaoAccountMetadataInterface private metadata;

  // --- PROPOSAL ATTRIBUTES

  /**
   * @notice Map data structure for fast access to the data of a proposal.
   */
  mapping(bytes32 => Proposal) internal proposals;

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
    LSP0ERC725Account _DAO,
    DaoUtils _utils,
    address daoAddress
  ) {
    DAO = _DAO;
    utils = _utils;
    permissions = DaoPermissionsInterface(daoAddress);
    delegates = DaoDelegatesInterface(daoAddress);
    metadata = DaoAccountMetadataInterface(daoAddress); 
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
   * @notice Verifies that a Universal Profile did not delegate his vote.
   */ 
  modifier didNotDelegate(address universalProfileAddress) {
    address delegatee = delegates._getDelegateeOfTheDelegator(universalProfileAddress);
    require(
      universalProfileAddress == delegatee || universalProfileAddress == address(0)
    );
    _;
  }

  /**
   * @notice Verifying if the voting delay has passed. 
   */
  modifier votingDelayPassed(bytes32 proposalSignature) {
    require(
      metadata._getDaoVotingDelay() + proposals[proposalSignature].creationTimestamp < block.timestamp,
      "The voting delay is not yeat over."
    );
    _;
  }

  /**
   * @notice Verifying if the voting period has passed. 
   */
  modifier votingPeriodPassed(bytes32 proposalSignature) {
    require(
      metadata._getDaoVotingPeriod() + proposals[proposalSignature].votingTimestamp < block.timestamp,
      "The voting delay is not yeat over."
    );
    _;
  }

  /**
   * @notice Verifying if the voting period is still on.
   */
  modifier votingPeriodIsOn(bytes32 proposalSignature) {
    require(
      proposals[proposalSignature].votingTimestamp + metadata._getDaoVotingPeriod() > block.timestamp,
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
  function _getDaoProposalsArrayKeyByPhase(uint8 phaseNr) public pure returns(bytes32 key) {
    bytes6 phase;
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
      bytes4(keccak256("Proposals")),
      bytes2(0),
      bytes20(keccak256("ProposalsArray[]"))
    ));
  }

  /**
   * @notice Get the proposals array lenngth.
   */
  function _getProposalsArrayLength(uint8 phaseNr) public view returns(uint256 length) {
    length = uint256(bytes32(DAO.getData(_getDaoProposalsArrayKeyByPhase(phaseNr))));
  }

  /**
   * @notice Set the proposals array lenngth.
   */
  function _setProposalsArrayLength(uint256 length, uint8 phaseNr) internal {
    bytes memory newLength = bytes.concat(bytes32(length));
    DAO.setData(_getDaoProposalsArrayKeyByPhase(phaseNr), newLength);
  }

  /**
   * @notice Get Proposal by index.
   */
  function _getProposalByIndex(uint256 index, uint8 phaseNr) public view returns(bytes memory proposalSignature) {
    bytes16[2] memory daoProposalsArrayKeyHalfs = utils._bytes32ToTwoHalfs(_getDaoProposalsArrayKeyByPhase(phaseNr));
    bytes32 proposalKey = bytes32(bytes.concat(
      daoProposalsArrayKeyHalfs[0], bytes16(uint128(index))
    ));
    proposalSignature = DAO.getData(proposalKey);
  }

  /**
   * @notice Set Proposal by index.
   */
  function _setProposalByIndex(uint256 index, bytes32 _proposalSignature, uint8 phaseNr) internal {
    bytes16[2] memory daoProposalsArrayKeyHalfs = utils._bytes32ToTwoHalfs(_getDaoProposalsArrayKeyByPhase(phaseNr));
    bytes32 proposalKey = bytes32(bytes.concat(
      daoProposalsArrayKeyHalfs[0], bytes16(uint128(index))
    ));
    bytes memory proposalSignature = bytes.concat(_proposalSignature);
    DAO.setData(proposalKey, proposalSignature);
  }

  /**
   * @notice Get DAO proposal data.
   */
  function _getProposalData(bytes32 proposalSignature) public view returns(
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
   * @notice Save proposal to the Universal Profile.
   */
  function _saveProposal(bytes32 proposalSignature, uint8 phaseNr) internal {

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

  /**
   * @notice Remove proposal from Universal Profile.
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

}