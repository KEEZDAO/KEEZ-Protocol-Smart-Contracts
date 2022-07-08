// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
import "./UP_DAO_CONSTANTS.sol";

/**
 * @author B00ste
 * @title UniversalProfileGovernance
 * @custom:version 0.3
 */
contract UniversalProfileGovernance {
   
  /**
   * @notice Instance of the DAO Universal Profile.
   */
  LSP0ERC725Account DAO = new LSP0ERC725Account(address(this));

  /**
   * @notice Instance of the UP DAO Constants.
   */
  UP_DAO_CONSTANTS constants = new UP_DAO_CONSTANTS();

  /**
   * @notice Initialization of the Universal Profile as a DAO Profile;
   * This smart contract will be given all controller permissions.
   * We initialize the array of addresses with DAO permissions key to value 0x00.
   */
  constructor() {

    bytes32[] memory keysArray = new bytes32[](4);
    // DAO Permissions array key
    keysArray[0] = bytes32(constants.getArrayOfAddressesWithDAOPermissionsKey());
    // Controller addresses array key
    keysArray[1] = bytes32(0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3);
    // First element from controller addresses array key
    keysArray[2] = bytes32(bytes.concat(bytes16(0xdf30dba06db6a30e65354d9a64c60986), bytes16(0)));
    // This addresses permissions key
    keysArray[3] = bytes32(bytes.concat(bytes12(0x4b80742de2bf82acb3630000), bytes20(address(this))));

    bytes[] memory valuesArray = new bytes[](4);
    // DAO Permissions array value
    valuesArray[0] = bytes.concat(bytes16(0));
    // Controller addresses array value
    valuesArray[1] = bytes.concat(bytes32(uint256(1)));
    // First element from controller addresses array value
    valuesArray[2] = bytes.concat(bytes20(address(this)));
    // This addresses permissions value
    valuesArray[3] = bytes.concat(bytes32(0x0000000000000000000000000000000000000000000000000000000000007FFF));

    DAO.setData(keysArray, valuesArray);
  }

  // --- MODIFIERS

  modifier hasVotePermission(address universalProfileAddress) {
    bytes32 addressPermissionsKey = constants.getAddressDAOPermissionsKey(universalProfileAddress);
    bytes memory addressPermissions = DAO.getData(addressPermissionsKey);
    uint8 uintAddressPermissions = uint8(addressPermissions[31]);
    require(
      (uintAddressPermissions & (1 << 0) == 1),
      "This address doesn't have VOTE permission."
    );
    _;
  }

  modifier hasProposePermission(address universalProfileAddress) {
    bytes32 addressPermissionsKey = constants.getAddressDAOPermissionsKey(universalProfileAddress);
    bytes memory addressPermissions = DAO.getData(addressPermissionsKey);
    uint8 uintAddressPermissions = uint8(addressPermissions[31]);
    require(
      (uintAddressPermissions & (1 << 1) == 4),
      "This address doesn't have PROPOSE permission."
    );
    _;
  }

  // --- GETTERS & SETTERS

  /**
   * @notice Getter of the lenght of the array of addresses that have DAO permissions.
   */
  function getDAOAddressArrayLenght() public view returns(uint128 length) {
    length = uint128(bytes16(DAO.getData(constants.getArrayOfAddressesWithDAOPermissionsKey())));
  }

  // --- GENERAL METHODS

  /**
   * @notice Add permission to an address by index.
   * index 0 sets the VOTE permission.
   * index 1 sets the PROPOSE permission.
   * index 2 sets the VOTE&PROPOSE permission.
   */
  function addPermission(address universalProfileAddress, uint8 index) public returns(bytes[] memory, bytes[] memory) {
    uint128 addressArrayLength = getDAOAddressArrayLenght();
    bytes32 newAddressKey = constants.getAddressKeyByIndex(addressArrayLength);
    bytes20 newAddressValue = bytes20(universalProfileAddress);
    
    bytes32 addressPermissionsKey = constants.getAddressDAOPermissionsKey(universalProfileAddress);
    bytes32 addressPermissionsValue = constants.getPermissionsArrayElement(index);

    bytes32[] memory keysArray = new bytes32[](3);
    keysArray[0] = newAddressKey;
    keysArray[1] = constants.getArrayOfAddressesWithDAOPermissionsKey();
    keysArray[2] = addressPermissionsKey;

    bytes[] memory valuesArray = new bytes[](3);
    valuesArray[0] = bytes.concat(newAddressValue);
    valuesArray[1] = bytes.concat(bytes16((addressArrayLength +  1)));
    valuesArray[2] = bytes.concat(addressPermissionsValue);

    DAO.setData(keysArray, valuesArray);

    return(valuesArray, DAO.getData(keysArray));
  }

  function vote() external hasVotePermission(msg.sender) {

  }

}