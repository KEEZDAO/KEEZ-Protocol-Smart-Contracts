// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface DaoPermissionsInterface {

  function _getPermissionsByIndex(uint8 index) external view returns(bytes32 permission);

  function _getDaoAddressesArrayLength() external view returns(uint256 length);

  function _getDaoAddressByIndex(uint256 index) external view returns(bytes memory daoAddress);

  function _getAddressDaoPermission(address daoAddress) external view returns(bytes memory addressPermssions);

}