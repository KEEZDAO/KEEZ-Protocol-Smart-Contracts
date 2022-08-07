// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

/**
 * @author B00ste
 * @title IDaoPermissions
 * @custom:version 1
 */
interface IDaoPermissions {

  /**
   * @notice Get the message needet to be sign for awarding a set of permissions.
   */
  function getNewPermissionHash(address _from, address _to, bytes32 _permissions) external view returns(bytes32 _hash);

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
  
}