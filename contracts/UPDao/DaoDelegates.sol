// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
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
  LSP0ERC725Account private DAO;

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
  function init(LSP0ERC725Account _DAO, DaoUtils _utils, address daoAddress) external isNotInitialized() {
    require(!initialized, "The contract is already initialized.");
    DAO = _DAO;
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
    delegatee = address(bytes20(DAO.getData(delegateeOfTheDelegatorKey)));
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
    DAO.setData(delegateeOfTheDelegatorKey, delegateeOfTheDelegatorValue);
  }

  /**
   * @notice Get the length of the array of addresses that delegated the votes to a delegatee.
   *
   * @param delegatee Address of the delegatee.
   */
  function _getDelegatorsArrayLength(address delegatee) public view returns(uint256 length) {
    length = uint256(bytes32(DAO.getData(      
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
    DAO.setData(delegateesArrayOfDeleggatorsKey, newLength);
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
    delegator = address(bytes20(DAO.getData(delegateeAndIndexKey)));
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
    DAO.setData(delegateeAndIndexKey, delegateeAndIndexValue);
  }
  
}