// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface DaoAccountMetadataInterface {
  
  function _getDaoName() external view returns(string memory name);

  function _getDaoDescription() external view returns(string memory description);

  function _getDaoQuorum() external view returns(uint8 quorum);

  function _getDaoParticipationRate() external view returns(uint8 participationRate);

  function _getDaoVotingDelay() external view returns(uint256 votingDelay);

  function _getDaoVotingPeriod() external view returns(uint256 votingPeriod);

}