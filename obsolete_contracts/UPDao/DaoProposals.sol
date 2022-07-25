// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./LSP0ERC725Account.sol";
import "./Interfaces/DaoAccountMetadataInterface.sol";
import "./Utils/AccessControl.sol";
import "./Utils/DaoUtils.sol";

/**
 *
* @notice This smart contract is responsible for the proposals of a DAO.
* The DAO must have as a base smart contract the LSP0ERC725Account.
 *
 * @author B00ste
 * @title DaoProposals
 * @custom:version 0.92
 */
contract DaoProposals is AccessControl {

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

  /**
   * @notice Initializing the contract.
   */
  function init(LSP0ERC725Account _DAO, DaoUtils _utils, address daoAddress) external isNotInitialized() {
    require(!initialized, "The contract is already initialized.");
    DAO = _DAO;
    utils = _utils;
    initAccessControl(_utils, daoAddress);
    metadata = DaoAccountMetadataInterface(daoAddress);
    initialized = true;
  }

  // --- ATTRIBUTES

  /**
   * @notice Proposals array key.
   */
  bytes32 private proposalsArrayKey = bytes32(keccak256("ProposalsArray[]"));

  /**
   * @notice Proposal attribute key.
   */  
  bytes20[9] private proposalAttributeKeys = [
    bytes20(keccak256("Title")),
    bytes20(keccak256("Description")),
    bytes20(keccak256("CreationTimestamp")),
    bytes20(keccak256("VotingTimestamp")),
    bytes20(keccak256("EndTimestamp")), //todo add ending delay.
    bytes20(keccak256("Targets[]")),
    bytes20(keccak256("Datas[]")),
    bytes20(keccak256("AgainstVotes")),
    bytes20(keccak256("ProVotes"))
  ];

  // --- GETTERS & SETTERS

  /**
   * @notice Get proposal attribute key.
   */
  function _getProposalAttributeKeyByIndex(uint8 index) external view returns(bytes20 key) {
    key = proposalAttributeKeys[index];
  }

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
  function _setProposalsArrayLength(uint256 length) external isDao(msg.sender) isInitialized() {
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
  function _setProposalSignatureByIndex(uint256 index, bytes10 _proposalSignature) external isDao(msg.sender) isInitialized() {
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
  function _getAttributeKey(bytes10 proposalSignature, bytes20 proposalAttributeKey) public pure returns(bytes32 key) {
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
  function _setAttributeValue(bytes10 proposalSignature, bytes20 proposalAttributeKey, bytes memory value) external isDao(msg.sender) isInitialized() {
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
  function _setTargetsAndDatas(bytes10 proposalSignature, address[] memory targets, bytes[] memory datas) external isDao(msg.sender) isInitialized() {
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

  /**
   * @notice Get voted status of a Universal Profile for a proposal.
   */
  function _getVotedStatus(address universalProfileAddress, bytes10 proposalSignature) public view returns(bool result) {
    bytes32 key = bytes32(bytes.concat(
      bytes10(proposalSignature),
      bytes2(0),
      bytes20(universalProfileAddress)
    ));
    if(uint256(bytes32(DAO.getData(key))) == 1) {
      result = true;
    }
    else {
      result = false;
    }
  }

  /**
   * @notice Set voted status of a Universal Profile for a proposal.
   */
  function _setVotedStatus(address universalProfileAddress, bytes10 proposalSignature) external isDao(msg.sender) isInitialized() {
    bytes32 key = bytes32(bytes.concat(
      bytes10(proposalSignature),
      bytes2(0),
      bytes20(universalProfileAddress)
    ));
    DAO.setData(key, bytes.concat(bytes32(uint256(1))));
  }

}