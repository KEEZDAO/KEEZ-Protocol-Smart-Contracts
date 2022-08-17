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

  /**
   * @notice This event is emited every time a proposal is executed.
   *
   * @param proposalSignature The signature of the proposal that was executed.
   */
  event ProposalExecuted(bytes10 proposalSignature);

  /**
   * @notice Get the message needed to be signed for awarding a set of permissions.
   * 
   * @param _from The address that awards a set of permissions.
   * @param _to The address that receives a set of permissions.
   * @param _permissions The set of permissions that are awarded.
   * 
   * @return _hash The message neede to be signed for awarding a new permission.
   */
  function getNewPermissionHash(
    address _from,
    address _to,
    bytes32 _permissions
  ) external view returns(bytes32 _hash);

  /**
   * @notice Claim a permission using a signature.
   * 
   * @param _from The address that has awarded the set of permissions.
   * @param _permissions The set of permissions that are awarded.
   * @param _signature The signature needed for claiming the set of permissions.
   * 
   * Requirements:
   * - `_from` must have the ADD_PERMISSION permission.
   * - The signer of `_signature` must be `_from`.
   */
  function claimPermission(
    address _from,
    bytes32 _permissions,
    bytes memory _signature
  ) external;

  /**
   * @notice Add a permission.
   * 
   * @param _to The address that will receive new permissions.
   * @param _permissions The permissions that will be given to `_to`.
   * 
   * Requirements:
   * - `msg.sender` must have ADD_PERMISSION permission.
   */
  function addPermissions(
    address _to,
    bytes32 _permissions
  ) external;

  /**
   * @notice Remove a permission.
   * 
   * @param _to The address that will permissions removed.
   * @param _permissions The permissions that will be removed from `_to`.
   * 
   * Requirements:
   * - `msg.sender` must have REMOVE_PERMISSION permission.
   */
  function removePermissions(
    address _to,
    bytes32 _permissions
  ) external;

  /**
   * @notice Propose to execute methods on behalf of the multisig.
   * 
   * @param _title Title of the proposal. Used to create the proposal signature.
   * @param _payloads An array of payloads that will be executed if the proposal is successful.
   */
  function proposeExecution(
    string calldata _title,
    bytes[] calldata _payloads
  ) external;

  /**
   * @notice Create a unique hash for every proposal which should be hashed. 
   */

  /**
   * @notice Get the hash needed to be signed by the proposal voters.
   * 
   * @param _signer The address of the voter.
   * @param _proposalSignature The unique identifier of a proposal.
   * @param _response The choice of the voter. (true || false)
   * 
   * Requirements:
   * - `msg.sender` must have VOTE permission.
   * - `_signer` must be the same as the address that will sign the message.
   */
  function getProposalHash(
    address _signer,
    bytes10 _proposalSignature,
    bool _response
  ) external view returns(bytes32 _hash);

  /**
   * @notice Execute a proposal if you have all the necessary signatures.
   * 
   * @param _proposalSignature The unique identifier of a proposal.
   * @param _signatures An array of signatures representing votes.
   * @param _signers An array of addresses that are the signers of `_signatures`.
   */
  function execute(
    bytes10 _proposalSignature,
    bytes[] calldata _signatures,
    address[] calldata _signers
  ) external;

}