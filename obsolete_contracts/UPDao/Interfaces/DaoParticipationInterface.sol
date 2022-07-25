// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface DaoParticipationInterface {

  function _getArrayOfDaosLength(address universalProfileAddress) external view returns(uint256 length);
  function _setArrayOfDaosLength(address universalProfileAddress, uint256 length) external;

  function _getDaoFromArrayByIndex(address universalProfileAddress, uint128 index) external view returns(address daoAddress);
  function _setDaoToArrayByIndex(address universalProfileAddress, address daoAddress, uint128 index) external;

  function _getContollersArrayKey(address daoAddress) external pure returns(bytes32 controllersArrayKey);

  function _getControllersArrayLength(address universalProfileAddress, address daoAddress) external view returns(uint256 length);
  function _setControllersArrayLength(address universalProfileAddress, address daoAddress, uint256 length) external;

  function _getControllerByIndex(address universalProfileAddress, address daoAddress, uint128 index) external view returns(address controllerAddress);
  function _setControllerByIndex(address universalProfileAddress, address daoAddress, address controllerAddress, uint128 index) external;
  
  function _getParticipantOfDao(address universalProfileAddress, address daoAddress) external view returns(bool response);
  function _toggleParticipantOfDao(address universalProfileAddress, address daoAddress, bool isParticipant) external;

}