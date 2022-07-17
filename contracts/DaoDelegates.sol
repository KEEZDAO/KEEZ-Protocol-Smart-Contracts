// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
import "./DaoPermissionsInterface.sol";

/**
 * @author B00ste
 * @title DaoDelegates
 * @custom:version 0.7
 */
contract DaoDelegates {

  /**
   * @notice Instance of the DAO key manager.
   */
  LSP0ERC725Account private DAO;

  /**
   * @notice Instance for the DAO permissions contract.
   */
  DaoPermissionsInterface private permissions;

  constructor(LSP0ERC725Account _DAO) {
    DAO = _DAO;
  }

  // --- MODIFIERS

  /**
   * @notice Verifies if an Universal Profile has SEND_DELEGATE permission.
   */
  modifier hasSendDelegatePermission(address universalProfileAddress) {
    bytes memory addressPermissions = permissions._getAddressDaoPermission(universalProfileAddress);
    require(
      (uint256(bytes32(addressPermissions)) & (1 << 2) == 4),
      "This address doesn't have SEND_DELEGATE permission."
    );
    _;
  }

  /**
   * @notice Verifies if an Universal Profile has RECIEVE_DELEGATE permission.
   */
  modifier hasRecieveDelegatePermission(address universalProfileAddress) {
    bytes memory addressPermissions = permissions._getAddressDaoPermission(universalProfileAddress);
    require(
      (uint256(bytes32(addressPermissions)) & (1 << 3) == 8),
      "This address doesn't have RECIEVE_DELEGATE permission."
    );
    _;
  }

  // --- GETTERS & SETTERS

  /**
   * @notice Delegate vote to an address.
   */
  function _setDelegatee(address delegator, address delegatee) internal {
    bytes32 voteDelegateeKey = bytes32(bytes.concat(
      bytes6(keccak256("SingleDelegatee")),
      bytes4(keccak256("Delegatee")),
      bytes2(0),
      bytes20(delegator)
    ));
    bytes memory voteDelegatee = bytes.concat(bytes20(delegatee));
    DAO.setData(voteDelegateeKey, voteDelegatee);
  }

  /**
   * @notice Get delegatee of an Universal Profile
   */
  function _getDelegatee(address delegator) internal view returns(address delegatee) {
    bytes32 voteDelegateeKey = bytes32(bytes.concat(
      bytes6(keccak256("SingleDelegatee")),
      bytes4(keccak256("Delegatee")),
      bytes2(0),
      bytes20(delegator)
    ));
    delegatee = address(bytes20(DAO.getData(voteDelegateeKey)));
  }

  /**
   * @notice Delegate your vote to another participant of the DAO
   */
  function delegate(address delegator, address delegatee)
    external
    hasSendDelegatePermission(delegator)
    hasRecieveDelegatePermission(delegatee)
  {
    _setDelegatee(delegator, delegatee);
  }
  
}