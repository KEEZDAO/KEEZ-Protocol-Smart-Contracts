// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// getData(...)
import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
// setData(...), execute(...)
import {ILSP6KeyManager} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/ILSP6KeyManager.sol";

// Openzeppelin Utils.
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// LSP6 Constants
import {NotAuthorised} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Errors.sol";
import {setDataSingleSelector} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Constants.sol";

// Dao Constants
import {
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY,
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX,
  _LSP6KEY_ADDRESSPERMISSIONS_DAOPERMISSIONS_PREFIX,
  _PERMISSION_ADD_PERMISSIONS,
  _PERMISSION_REMOVE_PERMISSIONS,

  _DAO_PARTICIPANTS_ARRAY_KEY,
  _DAO_PARTICIPANTS_ARRAY_PREFIX,
  _DAO_PARTICIPANTS_MAPPING_PREFIX
} from "./DaoConstants.sol";

// Library for array interaction
import {ArrayWithMappingLibrary} from "../ArrayWithMappingLibrary.sol";

// Custom error
import {IndexedError} from "../Errors.sol";

// Contract's interface
import {IDaoPermissions} from "./IDaoPermissions.sol";

/**
 *
* @notice This smart contract is responsible for managing the DAO Permissions Keys.
 *
 * @author B00ste
 * @title DaoPermissions
 * @custom:version 1.2
 */
contract DaoPermissions is IDaoPermissions {
  using ECDSA for bytes32;

  /**
   * @dev Nonce for claiming permissions.
   */
  mapping(address => uint256) private claimPermissionNonce;

  /**
   * @notice Address of the DAO_ACCOUNT.
   */
  address payable private UNIVERSAL_PROFILE;

  /**
   * @notice Address of the KEY_MANAGER.
   */
  address private KEY_MANAGER;

  /**
   * @dev
   */
  constructor(
    address payable _UNIVERSAL_PROFILE,
    address _KEY_MANAGER
  ) {
    UNIVERSAL_PROFILE = _UNIVERSAL_PROFILE;
    KEY_MANAGER = _KEY_MANAGER;
  }


  // --- General Methods.


  /**
   * @inheritdoc IDaoPermissions
   */
  function getNewPermissionHash(
    address _from,
    address _to,
    bytes32 _permissions
  )
    public
    override
    view
    returns(bytes32 _hash)
  {
    _hash = keccak256(abi.encode(
      address(this),
      _from,
      _to,
      _permissions,
      claimPermissionNonce[_to]
    ));
  }

  /**
   * @inheritdoc IDaoPermissions
   */
  function claimPermission(
    address _from,
    bytes32 _permissions,
    bytes memory _signature
  )
    external
    override
  {
    _verifyPermission(_from, _PERMISSION_ADD_PERMISSIONS, "ADD_PERMISSION");
    bytes32 _hash = getNewPermissionHash(_from, msg.sender, _permissions).toEthSignedMessageHash();
    address recoveredAddress = _hash.recover(_signature);
    if (_from != recoveredAddress) revert IndexedError("DAO", 0x01);
    _addPermissions(msg.sender, _permissions);
    // Changing the nonce.
    claimPermissionNonce[msg.sender] += block.timestamp / 113;
  }

  /**
   * @inheritdoc IDaoPermissions
   */
  function addPermissions(
    address _to,
    bytes32 _permissions
  )
    external
    override
  {
    _verifyPermission(msg.sender, _PERMISSION_ADD_PERMISSIONS, "ADD_PERMISSION");
    _addPermissions(_to, _permissions);
  }

  /**
   * @inheritdoc IDaoPermissions
   */
  function removePermissions(
    address _to,
    bytes32 _permissions
  )
    external
    override
  {
    _verifyPermission(msg.sender, _PERMISSION_REMOVE_PERMISSIONS, "REMOVE_PERMISSION");
    _removePermissions(_to, _permissions);
  }


  // --- Internal Methods.


  /**
   * @dev Get the BitArray permissions of an address.
   */
  function _getPermissions(
    address _from
  )
    internal
    view
    returns(bytes32 permissions)
  {
    permissions = bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(
      _LSP6KEY_ADDRESSPERMISSIONS_DAOPERMISSIONS_PREFIX,
      bytes20(_from)
    ))));
  }

  /**
   * @dev Verify if an address has certain permission and revert if not.
   */
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

  /**
   * @dev Add `_permissions` to an address `_to`.
   */
  function _addPermissions(address _to, bytes32 _permissions) internal {
    // Check if user has any permisssions. If not add him to the list of participants.
    bytes32 currentPermissions = _getPermissions(_to);
    if (currentPermissions == bytes32(0))
    ArrayWithMappingLibrary._addElement(
      UNIVERSAL_PROFILE,
      KEY_MANAGER,
      _DAO_PARTICIPANTS_ARRAY_KEY,
      _DAO_PARTICIPANTS_ARRAY_PREFIX,
      _DAO_PARTICIPANTS_MAPPING_PREFIX,
      bytes.concat(bytes20(_to))
    );
    // Update the permissions in a local variable.
    for(uint256 i = 0; i < 7; i++) {
      if (currentPermissions & bytes32(1 << i) == 0 && _permissions & bytes32(1 << i) != 0)
      currentPermissions = bytes32(uint256(currentPermissions) + (1 << i));
    }
    // Set the local permissions to the Universal Profile.
    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataSingleSelector,
        bytes32(bytes.concat(
          _LSP6KEY_ADDRESSPERMISSIONS_DAOPERMISSIONS_PREFIX,
          bytes20(_to)
        )),
        bytes.concat(currentPermissions)
      )
    );
  }

  /**
   * @dev Remove `_permissions` from an address `_to`.
   */
  function _removePermissions(address _to, bytes32 _permissions) internal {
    // Update the permissions in a local variable.
    bytes32 currentPermissions = _getPermissions(_to);
    for(uint256 i = 0; i < 7; i++) {
      if (currentPermissions & bytes32(1 << i) != 0 && _permissions & bytes32(1 << i) != 0)
      currentPermissions = bytes32(uint256(currentPermissions) - (1 << i));
    }
    bytes memory encodedCurrentPermissions = bytes.concat(currentPermissions);
    // Check if user has any permissions left. If not, remove him from the list of participants.
    if (currentPermissions == bytes32(0)) {
      ArrayWithMappingLibrary._removeElement(
        UNIVERSAL_PROFILE,
        KEY_MANAGER,
        _DAO_PARTICIPANTS_ARRAY_KEY,
        _DAO_PARTICIPANTS_ARRAY_PREFIX,
        _DAO_PARTICIPANTS_MAPPING_PREFIX,
        bytes.concat(bytes20(_to))
      );
      encodedCurrentPermissions = "";
    }
    // Set the local permissions to the Universal Profile.
    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataSingleSelector,
        bytes32(bytes.concat(
          _LSP6KEY_ADDRESSPERMISSIONS_DAOPERMISSIONS_PREFIX,
          bytes20(_to)
        )),
        encodedCurrentPermissions
      )
    );
  }
  
}