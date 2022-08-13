// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

/**
 * @author B00ste
 * @title IDaoPermissions
 * @custom:version 1.5
 */
interface IDaoPermissions {

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
  
}