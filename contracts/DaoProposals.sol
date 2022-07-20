// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
import "./Interfaces/DaoAccountMetadataInterface.sol";
import "./DaoUtils.sol";

/**
 *
* @notice This smart contract is responsible for the proposals of a DAO.
* The DAO must have as a base smart contract the LSP0ERC725Account.
 *
 * @author B00ste
 * @title DaoProposals
 * @custom:version 0.91
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
   * @notice Instance for the DAO metadata.
   */
  DaoAccountMetadataInterface private metadata;

  // --- PROPOSAL ATTRIBUTES
  
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
    metadata = DaoAccountMetadataInterface(daoAddress); 
  }

  /**
   * @notice Proposals array key.
   */
  bytes32 private proposalsArrayKey = bytes32(keccak256("ProposalsArray[]"));

  /**
   * @notice Proposal attribute key.
   */  
  bytes20[9] internal proposalAttributeKeys = [
    bytes20(keccak256("Title")),
    bytes20(keccak256("Description")),
    bytes20(keccak256("CreationTimestamp")),
    bytes20(keccak256("VotingTimestamp")),
    bytes20(keccak256("EndTimestamp")),
    bytes20(keccak256("Targets[]")),
    bytes20(keccak256("Datas[]")),
    bytes20(keccak256("AgainstVotes")),
    bytes20(keccak256("ProVotes"))
  ];

  // --- MODIFIERS

  /**
   * @notice Verifying if the voting delay has passed. 
   */
  modifier votingDelayPassed(bytes10 proposalSignature) {
    require(
      metadata._getDaoVotingDelay() + uint256(bytes32(_getAttributeValue(proposalSignature, proposalAttributeKeys[2]))) < block.timestamp,
      "The voting delay is not yeat over."
    );
    _;
  }

  /**
   * @notice Verifying if the voting period has passed. 
   */
  modifier votingPeriodPassed(bytes10 proposalSignature) {
    require(
      metadata._getDaoVotingPeriod() + uint256(bytes32(_getAttributeValue(proposalSignature, proposalAttributeKeys[3]))) < block.timestamp,
      "The voting delay is not yet over."
    );
    _;
  }

  /**
   * @notice Verifying if the voting period is still on.
   */
  modifier votingPeriodIsOn(bytes10 proposalSignature) {
    require(
      metadata._getDaoVotingPeriod() + uint256(bytes32(_getAttributeValue(proposalSignature, proposalAttributeKeys[3]))) > block.timestamp,
      "Voting period is already over."
    );
    _;
  }

  // --- GETTERS & SETTERS

  /**
   * @notice Get proposal signature.
   */
  function _getProposalSignature(uint256 creationTimestamp, string memory proposalName) public pure returns(bytes10 proposalSignature) {
    proposalSignature = bytes10(bytes.concat(
      bytes6(keccak256(abi.encode(creationTimestamp))),
      bytes4(keccak256(bytes(proposalName)))
    ));
  }

  /**
   * @notice Get the proposals array lenngth.
   */
  function _getProposalsArrayLength() public view returns(uint256 length) {
    length = uint256(bytes32(DAO.getData(proposalsArrayKey)));
  }

  /**
   * @notice Set the proposals array lenngth.
   */
  function _setProposalsArrayLength(uint256 length) internal {
    bytes memory newLength = bytes.concat(bytes32(length));
    DAO.setData(proposalsArrayKey, newLength);
  }

  /**
   * @notice Get Proposal Signature by index.
   */
  function _getProposalSignatureByIndex(uint256 index) public view returns(bytes memory proposalSignature) {
    bytes16[2] memory daoProposalsArrayKeyHalfs = utils._bytes32ToTwoHalfs(proposalsArrayKey);
    bytes32 proposalKey = bytes32(bytes.concat(
      daoProposalsArrayKeyHalfs[0], bytes16(uint128(index))
    ));
    proposalSignature = DAO.getData(proposalKey);
  }

  /**
   * @notice Set Proposal by index.
   */
  function _setProposalSignatureByIndex(uint256 index, bytes10 _proposalSignature) internal {
    bytes16[2] memory daoProposalsArrayKeyHalfs = utils._bytes32ToTwoHalfs(proposalsArrayKey);
    bytes32 proposalKey = bytes32(bytes.concat(
      daoProposalsArrayKeyHalfs[0], bytes16(uint128(index))
    ));
    bytes memory proposalSignature = bytes.concat(_proposalSignature);
    DAO.setData(proposalKey, proposalSignature);
  }

  /**
   * @notice Get the key for a proposal attribute.
   */
  function _getAttributeKey(bytes10 proposalSignature, bytes20 proposalAttributeKey) internal pure returns(bytes32 key) {
    key = bytes32(bytes.concat(
      proposalSignature,
      bytes2(0),
      proposalAttributeKey
    ));
  }

  /**
   * @notice Get attribute value.
   */
  function _getAttributeValue(bytes10 proposalSignature, bytes20 proposalAttributeKey) public view returns(bytes memory value) {
    bytes32 key = _getAttributeKey(proposalSignature, proposalAttributeKey);
    value = DAO.getData(key);
  }

  /**
   * @notice Set attribute value.
   */
  function _setAttributeValue(bytes10 proposalSignature, bytes20 proposalAttributeKey, bytes memory value) internal {
    bytes32 key = _getAttributeKey(proposalSignature, proposalAttributeKey);
    DAO.setData(key, value);
  }

  /**
   * @notice Get the targets and datas for execution of a proposal.
   */
  function _getTargetsAndDatas(bytes10 proposalSignature) public view returns(address[] memory targets, bytes[] memory datas) {
    bytes32 targetsKey = _getAttributeKey(proposalSignature, proposalAttributeKeys[5]);
    bytes32 datasKey = _getAttributeKey(proposalSignature, proposalAttributeKeys[6]);
    uint256 arrayLength = uint256(bytes32(_getAttributeValue(proposalSignature, proposalAttributeKeys[5])));
    targets = new address[](arrayLength);
    datas = new bytes[](arrayLength);
    for(uint128 i = 0; i < arrayLength; i++) {
      targets[i] = address(bytes20(DAO.getData(bytes32(bytes.concat(
        utils._bytes32ToTwoHalfs(targetsKey)[0],
        bytes16(i)
      )))));
      datas[i] = DAO.getData(bytes32(bytes.concat(
        utils._bytes32ToTwoHalfs(datasKey)[0],
        bytes16(i)
      )));
    }
  }

  /**
   * @notice Set the targets and datas for execution of a proposal.
   */
  function _setTargetsAndDatas(bytes10 proposalSignature, address[] memory targets, bytes[] memory datas) internal {
    bytes32 targetsKey = _getAttributeKey(proposalSignature, proposalAttributeKeys[5]);
    bytes32 datasKey = _getAttributeKey(proposalSignature, proposalAttributeKeys[6]);
    uint256 arrayLength = targets.length;
    for(uint128 i = 0; i < arrayLength; i++) {
      DAO.setData(
        bytes32(bytes.concat(
          utils._bytes32ToTwoHalfs(targetsKey)[0],
          bytes16(i)
        )),
        bytes.concat(bytes20(targets[i]))
      );
      DAO.setData(
        bytes32(bytes.concat(
          utils._bytes32ToTwoHalfs(datasKey)[0],
          bytes16(i)
        )),
        datas[i]
      );
    }

  }

}