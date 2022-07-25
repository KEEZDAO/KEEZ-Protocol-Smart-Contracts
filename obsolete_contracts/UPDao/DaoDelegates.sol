// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./LSP0ERC725Account.sol";
import "./Interfaces/DaoPermissionsInterface.sol";
import "./Utils/AccessControl.sol";
import "./Utils/DaoUtils.sol";

/**
 * @author B00ste
 * @title DaoDelegates
 * @custom:version 0.92
 */
contract DaoDelegates is AccessControl {

  /**
   * @notice Instance of the DAO key manager.
   */
  address private UNIVERSAL_PROFILE;

  /**
   * @notice Instance for the utils of a Universal Profile DAO.
   */
  DaoUtils private utils;

  /**
   * @notice Instance for the DAO permissions contract.
   */
  DaoPermissionsInterface private permissions;

  /**
   * @notice Initializing the contract.
   */
  function init(address _UNIVERSAL_PROFILE, DaoUtils _utils, address daoAddress) external isNotInitialized() {
    require(!initialized, "The contract is already initialized.");
    UNIVERSAL_PROFILE = _UNIVERSAL_PROFILE;
    utils = _utils;
    initAccessControl(_utils, daoAddress);
    permissions = DaoPermissionsInterface(daoAddress);
    initialized = true;
  }

  // --- GETTERS & SETTERS

  /**
   * @notice Get the delgatee of the delegator.
   *
   * @param delegator Address of the delegator..
   */
  function _getDelegateeOfTheDelegator(address delegator) public view returns(address delegatee) {
    bytes32 delegateeOfTheDelegatorKey = bytes32(bytes.concat(
      bytes10(keccak256("Delegatee")),
      bytes2(0),
      bytes20(delegator)
    ));
    delegatee = address(bytes20(LSP0ERC725Account(UNIVERSAL_PROFILE).getData(delegateeOfTheDelegatorKey)));
  }

  /**
   * @notice Set the delgatee of the delegator.
   *
   * @param delegator Address of the delegator.
   * @param delegatee Address of the delegatee.
   */
  function _setDelegateeOfTheDelegator(address delegator, address delegatee) external isDao(msg.sender) isInitialized() {
    bytes32 delegateeOfTheDelegatorKey = bytes32(bytes.concat(
      bytes10(keccak256("Delegatee")),
      bytes2(0),
      bytes20(delegator)
    ));
    bytes memory delegateeOfTheDelegatorValue = bytes.concat(bytes20(delegatee)); 
    LSP0ERC725Account(UNIVERSAL_PROFILE).setData(delegateeOfTheDelegatorKey, delegateeOfTheDelegatorValue);
  }

  /**
   * @notice Get the length of the array of addresses that delegated the votes to a delegatee.
   *
   * @param delegatee Address of the delegatee.
   */
  function _getDelegatorsArrayLength(address delegatee) public view returns(uint256 length) {
    length = uint256(bytes32(UNIVERSAL_PROFILE.getData(      
      bytes32(bytes.concat(
        bytes6(keccak256("VotesDelegatedArray[]")),
        bytes4(keccak256("Delegatee")),
        bytes2(0),
        bytes20(delegatee)
      ))
    )));
  }

  /**
   * @notice Set the length of the array of addresses that delegated the votes to a delegatee.
   *
   * @param length the length of the array of addresses that delegated the votes to a delegatee.
   * @param delegatee Address of the delegatee.
   */
  function _setDelegatorsArrayLength(uint256 length, address delegatee) external isDao(msg.sender) isInitialized() {
    bytes32 delegateesArrayOfDeleggatorsKey = bytes32(bytes.concat(
      bytes6(keccak256("VotesDelegatedArray[]")),
      bytes4(keccak256("Delegatee")),
      bytes2(0),
      bytes20(delegatee)
    ));
    bytes memory newLength = bytes.concat(bytes32(length));
    LSP0ERC725Account(UNIVERSAL_PROFILE).setData(delegateesArrayOfDeleggatorsKey, newLength);
  }

  /**
   * @notice Get the delegator of the delagtee by index.
   *
   * @param delegatee Address of the delegatee.
   * @param index A number of the array.
   */
  function _getDelegatorByIndex(address delegatee, uint256 index) public view returns(address delegator) {
    bytes32 delegateeAndIndexKey = bytes32(bytes.concat(
      utils._bytes32ToTwoHalfs(
        bytes32(bytes.concat(
          bytes6(keccak256("VotesDelegatedArray[]")),
          bytes4(keccak256("Delegatee")),
          bytes2(0),
          bytes20(delegatee)
        ))
      )[0],
      bytes16(uint128(index))
    ));
    delegator = address(bytes20(LSP0ERC725Account(UNIVERSAL_PROFILE).getData(delegateeAndIndexKey)));
  }

  /**
   * @notice Set the delegator of the delagtee by index.
   *
   * @param delegator Address of the delegator.
   * @param delegatee Address of the delegatee.
   * @param index A number of the array.
   */
  function _setDelegatorByIndex(address delegator, address delegatee, uint256 index) external isDao(msg.sender) isInitialized() {
    bytes32 delegateeAndIndexKey = bytes32(bytes.concat(
      utils._bytes32ToTwoHalfs(
        bytes32(bytes.concat(
          bytes6(keccak256("VotesDelegatedArray[]")),
          bytes4(keccak256("Delegatee")),
          bytes2(0),
          bytes20(delegatee)
        ))
      )[0],
      bytes16(uint128(index))
    ));
    bytes memory delegateeAndIndexValue = bytes.concat(bytes20(delegator));
    LSP0ERC725Account(UNIVERSAL_PROFILE).setData(delegateeAndIndexKey, delegateeAndIndexValue);
  }
  
}