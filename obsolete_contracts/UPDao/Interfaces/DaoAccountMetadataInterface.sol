// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface DaoAccountMetadataInterface {

  function _getDaoName() external view returns(string memory name);
  function _setDaoName(string memory name) external;
  
  function _getDaoDescription() external view returns(string memory description);
  function _setDaoDescription(string memory description) external;

  function _getDaoMajority() external view returns(uint8 majority);
  function _setDaoMajority(uint8 majority) external;

  function _getDaoParticipationRate() external view returns(uint8 participationRate);
  function _setDaoParticipationRate(uint8 participationRate) external;

  function _getDaoVotingDelay() external view returns(uint256 votingDelay);
  function _setDaoVotingDelay(uint256 votingDelay) external;

  function _getDaoVotingPeriod() external view returns(uint256 votingPeriod);
  function _setDaoVotingPeriod(uint256 votingPeriod) external;

}