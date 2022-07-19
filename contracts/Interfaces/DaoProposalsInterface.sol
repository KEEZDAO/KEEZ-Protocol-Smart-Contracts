// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface DaoProposalsInterface {
  
  function getDaoProposalsArrayKeyByPhase(uint8 phaseNr) external pure returns(bytes32 key);

  function _getProposalsArrayLength(uint8 phaseNr) external view returns(uint256 length);

  function _getProposalByIndex(uint256 index, uint8 phaseNr) external view returns(bytes memory proposalSignature);

  function _getProposalData(bytes32 proposalSignature) external view returns(
      string memory title,
      string memory description,
      uint256 creationTimestamp,
      uint256 votingTimestamp,
      uint256 endTimestamp,
      uint256 againstVotes,
      uint256 proVotes,
      uint256 abstainVotes
  );

}