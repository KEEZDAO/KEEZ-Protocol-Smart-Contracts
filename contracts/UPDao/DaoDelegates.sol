// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
import "./Interfaces/DaoPermissionsInterface.sol";
import "./DaoUtils.sol";

/**
 * @author B00ste
 * @title DaoDelegates
 * @custom:version 0.91
 */
contract DaoDelegates {

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

  constructor(LSP0ERC725Account _DAO, DaoUtils _utils) {
    DAO = _DAO;
    utils = _utils;
  }

  // --- MODIFIERS

  /**
   * @notice Verifies that a Universal Profile did not delegate his vote.
   */ 
  modifier didNotDelegate(address universalProfileAddress) {
    address delegatee = _getDelegateeOfTheDelegator(universalProfileAddress);
    require(
      universalProfileAddress == delegatee || bytes20(universalProfileAddress) == bytes20(0),
      "User delegated his votes."
    );
    _;
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
  function _setDelegateeOfTheDelegator(address delegator, address delegatee) internal {
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
  function _setDelegatorsArrayLength(uint256 length, address delegatee) internal {
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
  function _setDelegatorByIndex(address delegator, address delegatee, uint256 index) internal {
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