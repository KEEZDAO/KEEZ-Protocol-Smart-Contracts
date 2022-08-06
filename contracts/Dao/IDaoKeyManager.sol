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
   * @notice This event is emited every time a proposal is created.
   *
   * @param proposalSignature The signature of the proposal that was created.
   */
  event ProposalCreated(bytes10 proposalSignature);

  /**
   * @notice Get the message needet to be sign for awarding a set of permissions.
   */
  function getNewPermissionHash(
    address _from,
    address _to,
    bytes32 _permissions
  ) external view returns(bytes32 _hash);

  /**
   * @notice Claim a permission using a signature
   */
  function claimPermission(address _from, bytes32 _permissions, bytes memory _signature) external;

  /**
   * @notice Add a permission.
   */
  function addPermissions(address _to, bytes32 _permissions) external;

  /**
   * @notice Remove a permission.
   */
  function removePermissions(address _to, bytes32 _permissions) external;

  /**
   * @notice Delegate your vote.
   */
  function delegate(address delegatee) external;

  /**
   *
   */
  function undelegate() external;

  /**
   * @notice Create a proposal.
   */
  function createProposal(
    string calldata _title,
    string calldata _metadataLink,
    uint48 _votingDelay,
    uint48 _votingPeriod,
    bytes[] calldata _payloads,
    uint8 _choices,
    uint8 _choicesPerVote
  ) external;

  /**
   *
   */
  function getProposalHash(
    address _signer,
    bytes10 _proposalSignature,
    bool _response
  )
    external
    view
    returns(bytes32 _hash);

  /**
   * @notice Execute the proposal by signature.
   */
  function executeProposal(bytes10 proposalSignature, bytes[] calldata _signatures, address[] calldata _signers) external;






}