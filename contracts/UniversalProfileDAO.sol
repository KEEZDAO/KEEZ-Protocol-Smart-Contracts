// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import "./UniversalProfileDAOGovernance.sol";

/**
 * @author B00ste
 * @title UniversalProfileDAO
 * @custom:version 0.6
 */
contract UniversalProfileDAO is UniversalProfileDAOGovernance {
   
  /**
   * @notice Instance of the DAO Universal Profile.
   */
  LSP0ERC725Account private DAO = new LSP0ERC725Account(address(this));

  /**
   * @notice Initialization of the Universal Profile as a DAO Profile;
   * This smart contract will be given all controller permissions.
   * We initialize the array of addresses with DAO permissions key to value 0x00.
   * Here is where the Universal Profile DAO Governance is initialized.
   *
   * @param _quorum The percentage of pro votes from the sum of pro and against votes needed for a proposal to pass.
   * @param _participationRate The percentage of pro and against votes compared to abstain votes needed for a proposal to pass.
   * @param _votingDelay Time required to pass before a proposal goes to the voting phase.
   * @param _votingPeriod Time allowed for voting on a proposal.
   */
  constructor(
    uint8 _quorum,
    uint8 _participationRate,
    uint256 _votingDelay,
    uint256 _votingPeriod
  )
    UniversalProfileDAOGovernance(
      _quorum,
      _participationRate,
      _votingDelay,
      _votingPeriod,
      DAO
    )
  {

    _setDaoAddressesArrayLength(0);
    _setProposalsArrayLength(0);

    bytes32[] memory keysArray = new bytes32[](3);
    // Controller addresses array key
    keysArray[0] = bytes32(0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3);
    // First element from controller addresses array key
    keysArray[1] = bytes32(bytes.concat(bytes16(0xdf30dba06db6a30e65354d9a64c60986), bytes16(0)));
    // This addresses permissions key
    keysArray[2] = bytes32(bytes.concat(bytes12(0x4b80742de2bf82acb3630000), bytes20(address(this))));


    bytes[] memory valuesArray = new bytes[](3);
    // Controller addresses array value
    valuesArray[0] = bytes.concat(bytes32(uint256(1)));
    // First element from controller addresses array value
    valuesArray[1] = bytes.concat(bytes20(address(this)));
    // This addresses permissions value
    valuesArray[2] = bytes.concat(bytes32(0x0000000000000000000000000000000000000000000000000000000000007FFF));

    DAO.setData(keysArray, valuesArray);
  }

  // --- MODIFIERS

  /**
   * @notice Verifies if an Universal Profile has EXECUTE permission.
   */
  modifier hasExecutePermission(address universalProfileAddress) {
    bytes memory addressPermissions = _getAddressDaoPermission(universalProfileAddress);
    require(
      (uint256(bytes32(addressPermissions)) & (1 << 2) == 4),
      "This address doesn't have EXECUTE permission."
    );
    _;
  }

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
   * index 0 sets the VOTE permission.
   * index 1 sets the PROPOSE permission.
   * index 2 sets the EXECUTE permission.
   *
   * @param universalProfileAddress The address of a Universal Profile.
   * @param index A number 0 <= `index` <= 2.
   */
  function addPermission(
    address universalProfileAddress,
    uint8 index
  ) 
    external
    permissionUnset(universalProfileAddress, _getPermissionsByIndex(index))
    returns(bytes32 addressPermssionsKey, bytes memory addressPermssions)
  {
    if (!checkUser(universalProfileAddress)) {
      uint256 addressesArrayLength = _getDaoAddressesArrayLength();
      _setDaoAddressByIndex(addressesArrayLength, universalProfileAddress);
      _setDaoAddressesArrayLength(addressesArrayLength + 1);
    }
    
    (addressPermssionsKey, addressPermssions) = _setAddressDaoPermission(universalProfileAddress, index, true);
  }

  /**
   * @notice Remove the permission of an Unversal Profile by index.
   * index 0 unsets the VOTE permission.
   * index 1 unsets the PROPOSE permission.
   * index 2 unsets the EXECUTE permission.
   *
   * @param universalProfileAddress The address of a Universal Profile.
   * @param index A number 0 <= `index` <= 2.
   */

  function removePermission(
    address universalProfileAddress,
    uint8 index
  ) 
    external
    permissionSet(universalProfileAddress, _getPermissionsByIndex(index))
    returns(bytes32 addressPermssionsKey, bytes memory addressPermssions)
  {
    (addressPermssionsKey, addressPermssions) = _setAddressDaoPermission(universalProfileAddress, index, false);
  }

}