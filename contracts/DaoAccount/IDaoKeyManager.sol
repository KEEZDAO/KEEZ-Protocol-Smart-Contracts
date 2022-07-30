// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

/**
 *
* @notice This smart contract is responsible for managing the DAO Keys.
 *
 * @author B00ste
 * @title DaoKeyManager
 * @custom:version 1
 */
interface IDaoKeyManager {

  /**
   * @notice Toggle permissions of an address.
   *
   * @param _to The Universal's Profile address whose permission will be toggled.
   * @param _permissions The array of permissions that will be toggled.
   */
  function togglePermissions(address _to, bytes32[] memory _permissions) external;

  /**
   * @notice Delegate your vote.
   */
  function delegate(address delegatee) external;

  /**
   * @notice Create a proposal.
   */
  function createProposal(string memory title, string memory metadataLink, uint48 votingDelay, uint48 votingPeriod, address[] memory targets, bytes[] memory datas, uint8 choices, uint8 choicesPerVote) external;

  /**
   * @notice Execute the calldata of the Proposal if there is one.
   */
  function executeProposal(bytes10 proposalSignature) external returns(bool[] memory success, bytes[] memory results);

  /**
   * @notice Vote on a proposal.
   */
  function vote(bytes10 proposalSignature, uint256[] memory choicesArray) external;

}