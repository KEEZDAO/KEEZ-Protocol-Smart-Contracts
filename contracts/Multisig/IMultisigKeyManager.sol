// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

/**
 *
* @notice This is an interface for MultisigKeyManager
 *
 * @author B00ste
 * @title IMultisigKeyManager
 * @custom:version 1.5
 */
interface IMultisigKeyManager {

  /**
   * @notice This event is emited every time a proposal is created.
   *
   * @param proposalSignature The signature of the proposal that was created.
   */
  event ProposalCreated(bytes10 proposalSignature);
  event ProposalExecuted(bytes10 proposalSignature);

  /**
   * @notice Create a `_hash` for signing and that signature can be used
   * by the user `_to` to redeem the permissions.
   */
  function getNewPermissionHash(address _from, address _to, bytes32 _permissions) external view returns(bytes32 _hash);

  /**
   * @notice User can claim a `_permission` if he recieved the `_signature`
   * from someone with the ADD_PERMISSION permission, otherwise it will revert.
   */
  function claimPermission(address _from, bytes32 _permissions, bytes memory _signature) external;

  /**
   * @notice 
   */
  function addPermissions(address _to, bytes32 _permissions) external;

  /**
   * @notice 
   */
  function removePermissions(address _to, bytes32 _permissions) external;

  /**
   * @notice Propose to execute methods on behalf of the multisig.
   */
  function proposeExecution(string calldata _title, bytes[] calldata _payloads) external;

  /**
   * @notice Create a unique hash for every proposal which should be hashed. 
   */
  function getProposalHash(address _signer, bytes10 _proposalSignature, bool _response) external view returns(bytes32 _hash);

  /**
   * @notice Execute a proposal if you have all the necessary signatures.
   */
  function execute(bytes10 _proposalSignature, bytes[] calldata _signatures, address[] calldata _signers) external;

}