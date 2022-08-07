// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

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
 * @custom:version 1.2
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
    _verifyPermission(msg.sender, _PERMISSION_SEND_DELEGATE, "SENDDELEGATE");
    _verifyPermission(delegatee, _PERMISSION_RECIEVE_DELEGATE, "RECIEVEDELEGATE");

    bytes32 delegateeKey = bytes32(bytes.concat(_DAO_DELEGATEE_PREFIX, bytes20(msg.sender)));
    bytes memory encodedDelegatee = IERC725Y(UNIVERSAL_PROFILE).getData(delegateeKey);

    if (bytes20(delegatee) == bytes20(encodedDelegatee)) revert IndexedError("DAO", 0x02);

    bytes32[] memory keys = new bytes32[](2);
    bytes[] memory values = new bytes[](2);

    keys[0] = delegateeKey;
    values[0] = bytes.concat(bytes20(delegatee));

    // Set the key of delegates array of the `delegatee`
    keys[1] = bytes32(bytes.concat(_DAO_DELEGATES_ARRAY_PREFIX, bytes20(delegatee)));
    // Get and decode delegates array of the `delegatee`
    address[] memory delegatesArray = abi.decode(
      IERC725Y(UNIVERSAL_PROFILE).getData(keys[1]),
      (address[])
    );
    // Update the delegates array of the `delegatee` with `msg.sender`
    delegatesArray[delegatesArray.length] = msg.sender;
    // Update the value of `keys[1]` with the new encoded array of addresses
    values[1] = abi.encode(delegatesArray);
  
    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataMultipleSelector,
        keys, values
      )
    );
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
    _verifyPermission(msg.sender, _PERMISSION_SEND_DELEGATE, "SENDDELEGATE");
    _verifyPermission(newDelegatee, _PERMISSION_RECIEVE_DELEGATE, "RECIEVEDELEGATE");

    bytes32 delegateeKey = bytes32(bytes.concat(_DAO_DELEGATEE_PREFIX, bytes20(msg.sender)));
    bytes20 encodedOldDelegatee = bytes20(IERC725Y(UNIVERSAL_PROFILE).getData(delegateeKey));
    bytes20 encodedNewDelegatee  = bytes20(newDelegatee);

    if (encodedNewDelegatee == encodedOldDelegatee) revert IndexedError("DAO", 0x02);

    bytes32[] memory keys = new bytes32[](3);
    bytes[] memory values = new bytes[](3);

    keys[0] = delegateeKey;
    values[0] = bytes.concat(encodedNewDelegatee);

    // Set the key for the delegates array of the `oldDelegatee`
    keys[1] = bytes32(bytes.concat(_DAO_DELEGATES_ARRAY_PREFIX, encodedOldDelegatee));
    // Get and decode the delegates array of the `oldDelegatee`
    address[] memory oldDelegateeDelegatesArray = abi.decode(
      IERC725Y(UNIVERSAL_PROFILE).getData(keys[0]),
      (address[])
    );
    // Remove `msg.sender` from the array of delegates of the old delegatee
    for (uint256 i = 0; i < oldDelegateeDelegatesArray.length; i++) {
      if (oldDelegateeDelegatesArray[i] == msg.sender) {
        oldDelegateeDelegatesArray[i] = oldDelegateeDelegatesArray[oldDelegateeDelegatesArray.length - 1];
        oldDelegateeDelegatesArray[oldDelegateeDelegatesArray.length - 1] = address(0);
      }
    }
    // Update the value of `keys[1]` with the new encoded array of addresses
    values[1] = abi.encode(oldDelegateeDelegatesArray);

    // Set the key for the delegates array of the `newDelegatee`
    keys[2] = bytes32(bytes.concat(_DAO_DELEGATES_ARRAY_PREFIX, encodedNewDelegatee));
    // Get and decode the delegates array of the `newDelegatee`
    address[] memory newDelegateeDelegatesArray = abi.decode(
      IERC725Y(UNIVERSAL_PROFILE).getData(keys[1]),
      (address[])
    );
    // Update the new delegatee's array of delegates with `msg.sender`
    newDelegateeDelegatesArray[newDelegateeDelegatesArray.length] = msg.sender;
    // Update the value of `keys[2]` with the new encoded array of addresses
    values[2] = abi.encode(newDelegateeDelegatesArray);
  
    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataMultipleSelector,
        keys, values
      )
    );
  }

  /**
   * TODO
   * @inheritdoc IDaoDelegates
   */
  function undelegate(

  )
    external
    override
  {

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

}