// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

/**
 * @author B00ste
 * @title UniversalProfileGovernance
 * @custom:version 0.2
 */
contract UniversalProfileGovernance {
   
  /**
   * @notice Instance of the DAO Universal Profile.
   */
  IERC725Y DAO;

  /**
   * @notice Permissions.
   * VOTE         = 0x0000000000000000000000000000000000000000000000000000000000000001;
   * PROPOSE      = 0x0000000000000000000000000000000000000000000000000000000000000002;
   * VOTE&PROPOSE = 0x0000000000000000000000000000000000000000000000000000000000000003;
   */
  bytes32[3] private permissions = [
    0x0000000000000000000000000000000000000000000000000000000000000001,
    0x0000000000000000000000000000000000000000000000000000000000000002,
    0x0000000000000000000000000000000000000000000000000000000000000003
  ];

  /**
   * @notice The key for getting the array of addresses that have a permission inside DAO.
   */
  bytes32 private ARRAY_KEY = bytes32(keccak256("AddressDAOPermissions[]"));

  /**
   * @notice Initialization using a constructor;
   */
  constructor(
    address universalProfileAddress 
  ) {
    DAO = IERC725Y(universalProfileAddress);

    bytes32 zero = bytes32(0);

    DAO.setData(ARRAY_KEY, zero);
  }

  // --- GETTERS & SETTERS

  /**
   * @notice Getter of the lenght of the array of addresses that have DAO permissions.
   */
  function getAddressArrayLenght() public view returns(uint128 length) {
    length = uint128(uint256(bytes32(DAO.getData(ARRAY_KEY))));
  }

  /**
   * @notice Getter for the key for getting the BitArray of permissiions of a specific address.
   */
  function getAddressPermissionsKey(address universalProfileAddress) public pure returns(bytes32 key) {
    key = bytes32(bytes.concat(
      bytes6(keccak256("AddressDAOPermissions")),
      bytes4(keccak256("DAOPermissions")),
      bytes2(0),
      bytes20(universalProfileAddress)
    ));
  }

  /**
   * @notice Getter for the key for getting an address that has DAO permissions by index.
   */
  function getAddressKeyByIndex(uint128 index) public view returns(bytes32 key) {
    bytes16[2] memory arrayKeyHalfs = _bytes32ToTwoHalfs(ARRAY_KEY);
    key = bytes32(bytes.concat(
      arrayKeyHalfs[0], bytes16(index)
    ));
  }

  // --- INTERNAL METHODS

  /**
   * @notice Split a bytes32 in half into two bytes16 values.
   */
  function _bytes32ToTwoHalfs(bytes32 source) internal pure returns(bytes16[2] memory y) {
    y = [bytes16(0), 0];
    assembly {
        mstore(y, source)
        mstore(add(y, 16), source)
    }
  }

  // --- GENERAL METHODS

  /**
   * @notice Add permission to an address by index.
   */
  function addPermission(address universalProfileAddress, uint8 index) public view {
    uint128 addressArrayLength = getAddressArrayLenght();
    bytes32 newAddressKey = getAddressKeyByIndex(addressArrayLength);
    bytes20 newAddressValue = bytes20(universalProfileAddress);
    //DAO.setData(newAddressKey, newAddressValue);
    //DAO.setData(ARRAY_KEY, bytes16(addressArrayLength +  1));
    
    bytes32 votingPermissionKey = getAddressPermissionsKey(universalProfileAddress);
    bytes32 votingPermissionValue = permissions[index];
    //DAO.setData(votingPermissionKey, votingPermissionValue);

    DAO.setData(
      [newAddressKey, ARRAY_KEY, votingPermissionKey],
      [newAddressValue, (addressArrayLength +  1), votingPermissionValue]
    );
  }

}