// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import "./DaoUtils.sol";

/**
 * @author B00ste
 * @title DaoParticipation
 * @custom:version 0.91
 */
contract DaoParticipation {

  // --- ATTRIBUTES

  /**
   * @notice Instance for the utils of a Universal Profile DAO.
   */
  DaoUtils private utils;

  constructor(DaoUtils _utils) {
    utils = _utils;
  }

  /**
   * @notice The key for the array of DAOs that a Universal Profile is a participant of.
   */
  bytes32 arrayOfDaosKey = bytes32(keccak256("ArrayOfDaos[]"));

  // --- GETTERS & SETTERS

  /**
   * @notice Get the length of the array of daos that the Universal Profile is a participant of.
   */
  function _getArrayOfDaosLength(address universalProfileAddress) public view returns(uint256 length) {
    IERC725Y UP = IERC725Y(universalProfileAddress);
    length = uint256(bytes32(UP.getData(arrayOfDaosKey)));
  }

  /**
   * @notice Set the length of the array of daos that the Universal Profile is a participant of.
   */
  function _setArrayOfDaosLength(address universalProfileAddress, uint256 length) internal {
    IERC725Y UP = IERC725Y(universalProfileAddress);
    UP.setData(arrayOfDaosKey, bytes.concat(bytes32(length)));
  }

  /**
   * @notice Get DAO from array by index.
   */
  function _getDaoFromArrayByIndex(address universalProfileAddress, uint128 index) public view returns(address daoAddress) {
    IERC725Y UP = IERC725Y(universalProfileAddress);
    bytes32 key = bytes32(bytes.concat(
      utils._bytes32ToTwoHalfs(arrayOfDaosKey)[0],
      bytes16(index)
    ));
    daoAddress = address(bytes20(UP.getData(key)));
  }

  /**
   * @notice Set DAO to array by index.
   */
  function _setDaoToArrayByIndex(address universalProfileAddress, address daoAddress, uint128 index) internal {
    IERC725Y UP = IERC725Y(universalProfileAddress);
    bytes32 key = bytes32(bytes.concat(
      utils._bytes32ToTwoHalfs(arrayOfDaosKey)[0],
      bytes16(index)
    ));
    UP.setData(key, bytes.concat(bytes20(daoAddress)));
  }

  /**
   * @notice Get the key for the array of controllers of a Universal Profile for a DAO.
   */
  function _getContollersArrayKey(address daoAddress) public pure returns(bytes32 controllersArrayKey) {
    controllersArrayKey = bytes32(bytes.concat(
      bytes10(keccak256("UPControllersForDaoArray[]")),
      bytes2(0),
      bytes20(daoAddress)
    ));
  }

  /**
   * @notice Get the length of the array of controllers of the a Universal Profile for a DAO.
   */
  function _getControllersArrayLength(address universalProfileAddress, address daoAddress) public view returns(uint256 length) {
    IERC725Y UP = IERC725Y(universalProfileAddress);
    length = uint256(bytes32(UP.getData(_getContollersArrayKey(daoAddress))));
  }

  /**
   * @notice Set the length of the array of controllers of the a Universal Profile for a DAO.
   */
  function _setControllersArrayLength(address universalProfileAddress, address daoAddress, uint256 length) internal {
    IERC725Y UP = IERC725Y(universalProfileAddress);
    UP.setData(_getContollersArrayKey(daoAddress), bytes.concat(bytes32(length)));
  }

  /**
   * @notice Get controller of the Universal Profile for the DAO.
   */
  function _getControllerByIndex(address universalProfileAddress, address daoAddress, uint128 index) public view returns(address controllerAddress) {
    IERC725Y UP = IERC725Y(universalProfileAddress);
    bytes32 key = bytes32(bytes.concat(
      utils._bytes32ToTwoHalfs(_getContollersArrayKey(daoAddress))[0],
      bytes16(index)
    ));
    controllerAddress = address(bytes20(UP.getData(key)));
  }

  /**
   * @notice Set controller of the Universal Profile for the DAO.
   */
  function _setControllerByIndex(address universalProfileAddress, address daoAddress, address controllerAddress, uint128 index) internal {
    IERC725Y UP = IERC725Y(universalProfileAddress);
    bytes32 key = bytes32(bytes.concat(
      utils._bytes32ToTwoHalfs(_getContollersArrayKey(daoAddress))[0],
      bytes16(index)
    ));
    UP.setData(key, bytes.concat(bytes20(controllerAddress)));
  }

}