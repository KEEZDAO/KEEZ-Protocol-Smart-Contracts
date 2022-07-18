// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
import "./DaoUtils.sol";

/**
 *
* @notice This smart contract is responsible for setting and getting the permesions of each participant to the DAO.
* The DAO must have as a base smart contract the LSP0ERC725Account.
 *
 * @author B00ste
 * @title DaoPermissions
 * @custom:version 0.8
 */
contract DaoPermissions {

  /**
   * @notice Instance of the DAO key manager.
   */
  LSP0ERC725Account private DAO;

  /**
   * @notice Instance for the utils of a Universal Profile DAO.
   */
  DaoUtils private utils;

  constructor(LSP0ERC725Account _DAO, DaoUtils _utils) {
    DAO = _DAO;
    utils = _utils;
  }

  /**
   * @notice Permissions.
   * VOTE              = 0x0000000000000000000000000000000000000000000000000000000000000001; // 0000 0001
   * PROPOSE           = 0x0000000000000000000000000000000000000000000000000000000000000002; // 0000 0010
   * SEND_DELEGATE     = 0x0000000000000000000000000000000000000000000000000000000000000004; // 0000 0100
   * RECIEVE_DELEGATE  = 0x0000000000000000000000000000000000000000000000000000000000000008; // 0000 1000
   * EXECUTE           = 0x0000000000000000000000000000000000000000000000000000000000000010; // 0001 0000
   */
  bytes32[5] private permissions = [
    bytes32(0x0000000000000000000000000000000000000000000000000000000000000001),
    0x0000000000000000000000000000000000000000000000000000000000000002,
    0x0000000000000000000000000000000000000000000000000000000000000004,
    0x0000000000000000000000000000000000000000000000000000000000000008,
    0x0000000000000000000000000000000000000000000000000000000000000010
  ];

  /**
   * @notice The key for the length of the array of aaddresses that have permissions in the DAO.
   */
  bytes32 private daoAddressesArrayKey = bytes32(keccak256("DAOPermissionsAddresses[]"));

  // --- MODIFIERS

  /**
   * @notice Verifies if an Universal Profile has a certain permision.
   */
  modifier permissionSet(address universalProfileAddress, bytes32 checkedPermission) {
    bytes memory addressPermissions = _getAddressDaoPermission(universalProfileAddress);
    require(
      uint256(bytes32(addressPermissions)) & uint256(checkedPermission) == uint256(checkedPermission),
      "User doesen't have the permission."
    );
    _;
  }

  /**
   * @notice Verifies if an Universal Profile doesn't have a certian permission.
   */
  modifier permissionUnset(address universalProfileAddress, bytes32 checkedPermission) {
    bytes memory addressPermissions = _getAddressDaoPermission(universalProfileAddress);
    require(
      uint256(bytes32(addressPermissions)) & uint256(checkedPermission) == 0,
      "User already has the permission."
    );
    _;
  }

  // --- GETTERS & SETTERS

  /**
   * @notice Get the the bytes32 permission from the permissions array.
   */
  function _getPermissionsByIndex(uint8 index) public view returns(bytes32 permission) {
    permission = permissions[index];
  }

  /**
   * @notice Get the length of the array of the addresses that are participants of the DAO.
   */
  function _getDaoAddressesArrayLength() public view returns(uint256 length) {
    length = uint256(bytes32(DAO.getData(daoAddressesArrayKey)));
  }

  /**
   * @notice Set the length of the array of the addresses that are participants of the DAO.
   *
   * @param length the length of the array of addresses that are participants to the DAO.
   */
  function _setDaoAddressesArrayLength(uint256 length) internal {
    bytes memory newLength = bytes.concat(bytes32(length));
    DAO.setData(daoAddressesArrayKey, newLength);
  }

  /**
   * @notice Get an address of a DAO perticipant by index.
   *
   * @param index The index of the an address.
   */
  function _getDaoAddressByIndex(uint256 index) public view returns(bytes memory daoAddress) {
    bytes16[2] memory daoAddressesArrayKeyHalfs = utils._bytes32ToTwoHalfs(daoAddressesArrayKey);
    bytes32 daoAddressKey = bytes32(bytes.concat(
      daoAddressesArrayKeyHalfs[0], bytes16(uint128(index))
    ));
    daoAddress = DAO.getData(daoAddressKey);
  }

  /**
   * @notice Set an address of a DAO perticipant at an index.
   *
   * @param index The index of an address.
   * @param _daoAddress The address of a DAO participant.
   */
  function _setDaoAddressByIndex(uint256 index, address _daoAddress) internal {
    bytes16[2] memory daoAddressesArrayKeyHalfs = utils._bytes32ToTwoHalfs(daoAddressesArrayKey);
    bytes32 daoAddressKey = bytes32(bytes.concat(
      daoAddressesArrayKeyHalfs[0], bytes16(uint128(index))
    ));
    bytes memory daoAddress = bytes.concat(bytes20(_daoAddress));
    DAO.setData(daoAddressKey, daoAddress);
  }

  /**
   * @notice Get addresses DAO permmissions BitArray.
   *
   * @param daoAddress The address of a DAO participant.
   */
  function _getAddressDaoPermission(address daoAddress) public view returns(bytes memory addressPermssions) {
    bytes32 addressPermssionsKey = bytes32(bytes.concat(
      bytes6(keccak256("DAOPermissionsAddresses")),
      bytes4(keccak256("DAOPermissions")),
      bytes2(0),
      bytes20(daoAddress)
    ));
    addressPermssions = DAO.getData(addressPermssionsKey);
  }

  /**
   * @notice Set addresses DAO permmissions BitArray by index.
   *
   * @param daoAddress The address of a DAO participant.
   * @param index The index of the permissions array.
   * Index 0 is the VOTE permission.
   * Index 1 is the PROPOSE permission.
   * Index 2 is the SEND_DELEGATE permission.
   * Index 3 is the RECIEVE_DELEGATE permission.
   * Index 4 is the EXECUTE permission.
   */
  function _setAddressDaoPermission(address daoAddress, uint8 index, bool permissionAdded) internal {
    bytes32 addressPermssionsKey = bytes32(bytes.concat(
      bytes6(keccak256("DAOPermissionsAddresses")),
      bytes4(keccak256("DAOPermissions")),
      bytes2(0),
      bytes20(daoAddress)
    ));
    bytes memory addressPermssions;
    if (permissionAdded) {
      addressPermssions = bytes.concat(
        bytes32(uint256(bytes32(DAO.getData(addressPermssionsKey))) + uint256(permissions[index]))
      );
    }
    else {
      addressPermssions = bytes.concat(
        bytes32(uint256(bytes32(DAO.getData(addressPermssionsKey))) - uint256(permissions[index]))
      );
    }
    DAO.setData(addressPermssionsKey, addressPermssions);
  }

  // --- GENERAL METHODS

  /**
   * @notice Check if a Universal Profile is a participant of the DAO
   *
   * @param universalProfileAddress The address of an Universal Profile.
   */
  function checkUser(address universalProfileAddress) internal view returns(bool) {
    uint256 addressesArrayLength = _getDaoAddressesArrayLength();
    for (uint256 i = 0; i < addressesArrayLength; i++) {
      bytes memory daoAddress = _getDaoAddressByIndex(i);
      if (address(bytes20(daoAddress)) == universalProfileAddress) {
        return true;
      }
    }
    return false;
  }

  /**
   * @notice Add permission to an address by index.
   * Index 0 sets the VOTE permission.
   * Index 1 sets the PROPOSE permission.
   * Index 2 sets the SEND_DELEGATE permission.
   * Index 3 sets the RECIEVE_DELEGATE permission.
   * Index 4 sets the EXECUTE permission.
   *
   * @param universalProfileAddress The address of a Universal Profile.
   * @param index A number 0 <= `index` <= 4.
   */
  function addPermission(
    address universalProfileAddress,
    uint8 index
  ) 
    external
    permissionUnset(universalProfileAddress, _getPermissionsByIndex(index))
  {
    if (!checkUser(universalProfileAddress)) {
      uint256 addressesArrayLength = _getDaoAddressesArrayLength();
      _setDaoAddressByIndex(addressesArrayLength, universalProfileAddress);
      _setDaoAddressesArrayLength(addressesArrayLength + 1);
    }
    
    _setAddressDaoPermission(universalProfileAddress, index, true);
  }

  /**
   * @notice Remove the permission of an Unversal Profile by index.
   * Index 0 unsets the VOTE permission.
   * Index 1 unsets the PROPOSE permission.
   * Index 2 unsets the SEND_DELEGATE permission.
   * Index 3 unsets the RECIEVE_DELEGATE permission.
   * Index 4 unsets the EXECUTE permission.
   *
   * @param universalProfileAddress The address of a Universal Profile.
   * @param index A number 0 <= `index` <= 4.
   */

  function removePermission(
    address universalProfileAddress,
    uint8 index
  ) 
    external
    permissionSet(universalProfileAddress, _getPermissionsByIndex(index))
  {
    _setAddressDaoPermission(universalProfileAddress, index, false);
  }

}