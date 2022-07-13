// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;
import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";

/**
 * @author B00ste
 * @title UniversalProfileDAOConstants
 * @custom:version 0.1
 */
contract UniversalProfileDAOConstants {

  /**
   * @notice Permissions.
   * VOTE    = 0x0000000000000000000000000000000000000000000000000000000000000001;
   * PROPOSE = 0x0000000000000000000000000000000000000000000000000000000000000002;
   * EXECUTE = 0x0000000000000000000000000000000000000000000000000000000000000004;
   */
  bytes32[3] private DAO_PERMISSIONS = [
    bytes32(0x0000000000000000000000000000000000000000000000000000000000000001),
    0x0000000000000000000000000000000000000000000000000000000000000002,
    0x0000000000000000000000000000000000000000000000000000000000000004
  ];

  /**
   * @notice The key for getting the array of addresses that have a permission inside DAO.
   */
  bytes32 private ARRAY_OF_ADDRESSES_WITH_DAO_PERMISSIONS_KEY = bytes32(keccak256("DAOPermissionsAddresses[]"));

  // --- GETTERS

  /**
   * @notice Getter for the permissions array.
   */
  function getPermissionsArray() external view returns(bytes32[3] memory res) {
    res = DAO_PERMISSIONS;
  }

  /**
   * @notice Getter for the permissions array by index.
   */
  function getPermissionsArrayElement(uint8 index) external view returns(bytes32 res) {
    res = DAO_PERMISSIONS[index];
  }

  /**
   * @notice Getter for the addresses array with dao permission.
   */
  function getArrayOfAddressesWithDAOPermissionsKey() external view returns(bytes32 res) {
    res = ARRAY_OF_ADDRESSES_WITH_DAO_PERMISSIONS_KEY;
  }

  /**
   * @notice Getter for the key for getting the BitArray of permissiions of a specific address.
   */
  function getAddressDAOPermissionsKey(address universalProfileAddress) external pure returns(bytes32 key) {
    key = bytes32(bytes.concat(
      bytes6(keccak256("DAOPermissionsAddresses")),
      bytes4(keccak256("DAOPermissions")),
      bytes2(0),
      bytes20(universalProfileAddress)
    ));
  }

  /**
   * @notice Getter for the key for getting an address that has DAO permissions by index.
   */
  function getAddressKeyByIndex(uint128 index) external view returns(bytes32 key) {
    bytes16[2] memory arrayKeyHalfs = _bytes32ToTwoHalfs(ARRAY_OF_ADDRESSES_WITH_DAO_PERMISSIONS_KEY);
    key = bytes32(bytes.concat(
      arrayKeyHalfs[0], bytes16(index)
    ));
  }

  /**
   * @notice Getter for the Proposals array key.
   */
  function getProposalArrayKey() external pure returns(bytes32 key) {
    key = bytes32(keccak256("ProposalsArray[]"));
  }

  // --- INTERNAL METHODS

  /**
   * @notice Split a bytes32 in half into two bytes16 values.
   */
  function _bytes32ToTwoHalfs(bytes32 source) public pure returns(bytes16[2] memory y) {
    y = [bytes16(0), 0];
    assembly {
        mstore(y, source)
        mstore(add(y, 16), source)
    }
  }

}