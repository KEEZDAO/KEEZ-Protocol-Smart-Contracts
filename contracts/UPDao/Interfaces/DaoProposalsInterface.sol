// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface DaoProposalsInterface {

  function _getProposalSignature(uint256 creationTimestamp, string memory proposalName) external pure returns(bytes10 proposalSignature);

  function _getProposalsArrayLength() external view returns(uint256 length);

  function _getProposalSignatureByIndex(uint256 index) external view returns(bytes memory proposalSignature);

  function _getAttributeValue(bytes10 proposalSignature, bytes20 proposalAttributeKey) external view returns(bytes memory value);

  function _getTargetsAndDatas(bytes10 proposalSignature) external view returns(address[] memory targets, bytes[] memory datas);

}