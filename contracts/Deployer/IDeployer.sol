// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;

interface IDeployer {

  /**
   * @dev Get UP data
   */
  function getData(
    address _caller,
    bytes32[] memory dataKeys
  ) external view returns (bytes[] memory dataValues);

  /**
   * @dev Set UP data
   */
  function setData(
    address _caller,
    bytes32[] memory dataKeys,
    bytes[] memory dataValues
  ) external;

  /**
   * @dev Set data of a Universal Profile
   */
  function setDataOf(
    address _UNIVERSAL_PROFILE,
    bytes32[] memory dataKeys,
    bytes[] memory dataValues
  ) external;

}