// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.10;

// getData(...)
import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
// setData(...), execute(...)
import {ILSP6KeyManager} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/ILSP6KeyManager.sol";

// LSP6 Constants
import {NotAuthorised} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Errors.sol";
import {setDataMultipleSelector} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Constants.sol";

// Dao Constants
import {
  _LSP6KEY_ADDRESSPERMISSIONS_DAOPERMISSIONS_PREFIX,
  _PERMISSION_SEND_DELEGATE,
  _PERMISSION_RECIEVE_DELEGATE,

  _DAO_DELEGATEE_PREFIX,
  _DAO_DELEGATES_ARRAY_PREFIX
} from "./DaoConstants.sol";

// Custom error
import {IndexedError} from "../Errors.sol";

// Contract's interface
import {IDaoDelegates} from "./IDaoDelegates.sol";

/**
 *
* @notice This smart contract is responsible for managing the DAO Delegates Keys.
 *
 * @author B00ste
 * @title DaoDelegates
 * @custom:version 1.5
 */
contract DaoDelegates is IDaoDelegates {

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
   * @inheritdoc IDaoDelegates
   */
  function delegate(
    address delegatee
  )
    external
    override
  {
    _verifyPermission(msg.sender, _PERMISSION_SEND_DELEGATE, "SEND_DELEGATE");
    _verifyPermission(delegatee, _PERMISSION_RECIEVE_DELEGATE, "RECIEVE_DELEGATE");

    bytes32[] memory keys = new bytes32[](2);
    bytes[] memory values = new bytes[](2);

    // The key for the curent delegatee of `msg.sender`
    keys[0] = bytes32(bytes.concat(_DAO_DELEGATEE_PREFIX, bytes20(msg.sender)));
    // Get the current enoded delgatee of the `msg.sender`
    bytes memory encodedDelegatee = IERC725Y(UNIVERSAL_PROFILE).getData(keys[0]);
    // Revert if `msg.sender` already has a delegatee
    if (encodedDelegatee.length > 0) revert IndexedError("DaoDelegates", 0x01);
    // Set the `delegatee` for `msg.sender`
    values[0] = bytes.concat(bytes20(delegatee));
    // Set the key of delegates array of the `delegatee`
    keys[1] = bytes32(bytes.concat(_DAO_DELEGATES_ARRAY_PREFIX, bytes20(delegatee)));
    // Get and decode delegates array of the `delegatee`
    bytes memory encodedDelegatesArray = IERC725Y(UNIVERSAL_PROFILE).getData(keys[1]);
    // Set the encoded delegates array updated with `msg.sender`
    values[1] = _addAddressToArray(msg.sender, encodedDelegatesArray);

    // Update the `keys` of Universal Profile with the `values`
    _setDataMultiple(keys, values);
  }

  /**
   * @inheritdoc IDaoDelegates
   */
  function changeDelegate(
    address newDelegatee
  )
    external
    override
  {
    _verifyPermission(msg.sender, _PERMISSION_SEND_DELEGATE, "SEND_DELEGATE");
    _verifyPermission(newDelegatee, _PERMISSION_RECIEVE_DELEGATE, "RECIEVE_DELEGATE");

    bytes32[] memory keys = new bytes32[](3);
    bytes[] memory values = new bytes[](3);

    // The key for the `msg.sender` delegatee
    keys[0] = bytes32(bytes.concat(_DAO_DELEGATEE_PREFIX, bytes20(msg.sender)));
    bytes memory encodedOldDelegatee = IERC725Y(UNIVERSAL_PROFILE).getData(keys[0]);
    bytes20 encodedNewDelegatee  = bytes20(newDelegatee);
    // Revert if `msg.sender` doesn't have a delegatee set
    if (encodedOldDelegatee.length < 20) revert IndexedError("DaoDelegates", 0x02);
    // Revert if the `encodedNewDelegatee` is the same with the `encodedOldDelegatee`
    if (encodedNewDelegatee == bytes20(encodedOldDelegatee)) revert IndexedError("DAO", 0x03);
    // Update the delegatee of `msg.sender`
    values[0] = bytes.concat(encodedNewDelegatee);

    // The key for the old delegatee's array of delegates
    keys[1] = bytes32(bytes.concat(_DAO_DELEGATES_ARRAY_PREFIX, encodedOldDelegatee));
    // Set the encoded delegates array of the old delegatee with `msg.sender` removed
    values[1] = _removeAddressFromArray(msg.sender, IERC725Y(UNIVERSAL_PROFILE).getData(keys[1]));
    
    // The key for the new delegatee's array of delegates
    keys[2] = bytes32(bytes.concat(_DAO_DELEGATES_ARRAY_PREFIX, encodedNewDelegatee));
    // Set the encoded delegates array of the new delegatee updated with `msg.sender`
    values[2] = _addAddressToArray(msg.sender, IERC725Y(UNIVERSAL_PROFILE).getData(keys[2]));

    // Update the `keys` of Universal Profile with the `values`
    _setDataMultiple(keys, values);
  }

  /**
   * TODO
   * @inheritdoc IDaoDelegates
   */
  function undelegate()
    external
    override
  {
    _verifyPermission(msg.sender, _PERMISSION_SEND_DELEGATE, "SEND_DELEGATE");

    bytes32[] memory keys = new bytes32[](2);
    bytes[] memory values = new bytes[](2);

    keys[0] = bytes32(bytes.concat(_DAO_DELEGATEE_PREFIX, bytes20(msg.sender)));
    bytes memory encodedOldDelegatee = IERC725Y(UNIVERSAL_PROFILE).getData(keys[0]);
    // Revert if the delegatee is empty
    if(encodedOldDelegatee.length == 0) revert IndexedError("DaoDelegates", 0x04);
    // Update the delegatee with zero value
    values[0] = "";

    // The key for the old delegatee's array of delegates
    keys[1] = bytes32(bytes.concat(_DAO_DELEGATES_ARRAY_PREFIX, encodedOldDelegatee));
    // Set the encoded delegates array of the old delegatee with `msg.sender` removed
    values[1] = _removeAddressFromArray(msg.sender, IERC725Y(UNIVERSAL_PROFILE).getData(keys[1]));

    // Update the `keys` of Universal Profile with the `values`
    _setDataMultiple(keys, values);
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
   * @dev Set data, multiple keys, of the Universal Profile through Key Manager
   */
  function _setDataMultiple(
    bytes32[] memory _keys,
    bytes[] memory _values
  )
    internal
  {
    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataMultipleSelector,
        _keys, _values
      )
    );
  }

  /**
   * @dev Add address to the encoded with `abi.encode(address[])` array
   */
  function _addAddressToArray(
    address newElement,
    bytes memory enocdedAddressArray
  )
    internal
    pure
    returns (bytes memory updatedEncodedAddressArray)
  {
    if (enocdedAddressArray.length != 0) {
      // abi.encode(address[])
      // Take the length from enocded with `abi.enocde(address[])` address array
      bytes memory delegatesArrayLength = bytes.concat(bytes32(0));
      for (uint256 i = 0; i < 32; i++) {
        delegatesArrayLength[i] = enocdedAddressArray[32 + i];
      }
      // Increase the length with 1
      bytes memory upadtedLength = bytes.concat(bytes32(
        uint256(bytes32(delegatesArrayLength)) + 1
      ));
      // Updated the encoded with `abi.encode(address[])` address array length
      for(uint256 i = 0; i < 32; i++) {
        enocdedAddressArray[32 + i] = upadtedLength[i];
      }
      // Concateneate the new address to the encoded with `abi.enocde(address[])` address array
      updatedEncodedAddressArray = bytes.concat(
        enocdedAddressArray,
        bytes12(0),
        bytes20(newElement)
      );
    }
    else {
      // abi.encode(address[])
      updatedEncodedAddressArray = bytes.concat(
        bytes31(0),
        bytes1(uint8(32)),
        bytes32(uint256(1)),
        bytes12(0),
        bytes20(newElement)
      );
    }
  }

  /**
   * @dev Remove address from the encoded with `abi.encode(address[])` array
   */
  function _removeAddressFromArray(
    address removedElement,
    bytes memory enocdedAddressArray
  )
    internal
    pure
    returns (bytes memory updatedEncodedAddressArray)
  {
    /**
     * Save the number resulted from dividing `enocdedAddressArray.length` by 32
     * We use this number to split an save `enocdedAddressArray` in parts of `bytes32`
     */
    uint256 bytes32ArrayLength = enocdedAddressArray.length/32;
    // The array of `bytes32` created from `enocdedAddressArray`
    bytes32[] memory bytes32array = new bytes32[](bytes32ArrayLength);
    // First element will be the lenght of each element in the `enocdedAddressArray`
    bytes32array[0] = bytes32(enocdedAddressArray);
    // Spitting `enocdedAddressArray` in multiple `bytes32` elements
    for(uint256 i = 2; i <= bytes32ArrayLength; i++) {
      bytes32 bytes32ArrayElement;
      bytes32 positionOfBytes32 = bytes32(uint256(bytes32array[0]) * i);
      assembly {
        bytes32ArrayElement := mload(add(enocdedAddressArray, positionOfBytes32))
      }
      bytes32array[i-1] = bytes32ArrayElement;
    }

    // Encoding `removedElement` correctly for comparing
    bytes32 encodedRemovedElement = bytes32(bytes.concat(bytes12(0), bytes20(removedElement)));
    if (bytes32array.length ==  3) {
      if (bytes32array[2] == encodedRemovedElement) updatedEncodedAddressArray = "";
    }
    else if (bytes32array.length > 3) {
      // Finding `removedElement` and swapping with the last element of the array
      for (uint i = 0; i < bytes32array.length - 1; i++) {
        if(encodedRemovedElement == bytes32array[i]) {
          updatedEncodedAddressArray = bytes.concat(
            updatedEncodedAddressArray, bytes32array[bytes32array.length - 1]
          );
        }
        else if(i == 1) {
          updatedEncodedAddressArray = bytes.concat(
            updatedEncodedAddressArray, bytes32(uint256(bytes32array[i]) - 1)
          );
        }
        else {
          updatedEncodedAddressArray = bytes.concat(
            updatedEncodedAddressArray, bytes32array[i]
          );
        }
      }
    }

  }

}