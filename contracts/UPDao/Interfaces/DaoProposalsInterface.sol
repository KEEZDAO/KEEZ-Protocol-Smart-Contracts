// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface DaoProposalsInterface {

  function _getProposalAttributeKeyByIndex(uint8 index) external pure returns(bytes20 key);
  
  function _getProposalSignature(uint256 creationTimestamp, string memory proposalName) external pure returns(bytes10 proposalSignature);
  
  function _getProposalsArrayLength() external view returns(uint256 length);
  function _setProposalsArrayLength(uint256 length) external;

  function _getProposalSignatureByIndex(uint256 index) external view returns(bytes memory proposalSignature);
  function _setProposalSignatureByIndex(uint256 index, bytes10 _proposalSignature) external;

  
  function _getAttributeKey(bytes10 proposalSignature, bytes20 proposalAttributeKey) external pure returns(bytes32 key);
  
  function _getAttributeValue(bytes10 proposalSignature, bytes20 proposalAttributeKey) external view returns(bytes memory value);
  function _setAttributeValue(bytes10 proposalSignature, bytes20 proposalAttributeKey, bytes memory value) external;
  
  function _getTargetsAndDatas(bytes10 proposalSignature) external view returns(address[] memory targets, bytes[] memory datas);
  function _setTargetsAndDatas(bytes10 proposalSignature, address[] memory targets, bytes[] memory datas) external;
  
  function _getVotedStatus(address universalProfileAddress, bytes10 proposalSignature) external view returns(bool result);
  function _setVotedStatus(address universalProfileAddress, bytes10 proposalSignature) external;
  
}