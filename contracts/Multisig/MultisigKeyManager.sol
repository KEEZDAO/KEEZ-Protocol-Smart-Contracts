// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import {LSP6KeyManager} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6KeyManager.sol";
import {
  NoPermissionsSet,
  NotAuthorised
} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Errors.sol";
import {
  _LSP6KEY_ADDRESSPERMISSIONS_MULTISIGPERMISSIONS_PREFIX,

  _PERMISSION_VOTE,
  _PERMISSION_PROPOSE
} from "./MultisigConstants.sol";

/**
 *
* @notice This smart contract is responsible for managing the Multisig Keys.
 *
 * @author B00ste
 * @title MultisigKeyManager
 * @custom:version 0.92
 */
contract MultisigKeyManager {

  /**
   * @notice Address of the DAO_ACCOUNT.
   */
  address payable private UNIVERSAL_PROFILE;

  /**
   * @notice Address of the KEY_MANAGER.
   */
  address private KEY_MANAGER;

  /**
   * @notice Address of the creator.
   */
  address private CREATOR;

  constructor(
    address payable _UNIVERSAL_PROFILE,
    address _KEY_MANAGER
  ) {
    UNIVERSAL_PROFILE = _UNIVERSAL_PROFILE;
    KEY_MANAGER = _KEY_MANAGER;
  }


  /**
   * @notice Propose to execute methods on behalf of the multisig.
   */
  function proposeExecution(
    address[] memory _targets,
    bytes[] memory _datas
  ) external {
    _verifyPermission(msg.sender, _PERMISSION_PROPOSE, "PROPOSE");

  }

  /**
   * @notice Sign a proposal.
   */
  function signProposal(
    bytes32 proposalSignature,
    bool response
  ) external {
    if (response) {

    }
    else {
        git
    }
  }

  /**
   * @notice Execute a proposal if you have all the necessary signatures.
   */
  function execute(
    bytes[] memory membersSignatures,
    string[] memory signedMessages
  ) external {
    // ToDo verify if there are enought signatures on-chain and off-chain 

  }


  // --- Internal Methods.


  function _getPermissions(
    address _from
  )
    internal
    view
    returns(bytes32 permissions)
  {
    permissions = bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(
      _LSP6KEY_ADDRESSPERMISSIONS_MULTISIGPERMISSIONS_PREFIX,
      bytes20(_from)
    ))));
  }

  function _verifyPermission(
    address _from,
    bytes32 _permission,
    string memory _permissionName
  )
    internal
    view
  {
    bytes32 permissions = _getPermissions(_from);
    if(permissions & _permission == 0) revert NotAuthorised(_from, _permissionName);
  }

}