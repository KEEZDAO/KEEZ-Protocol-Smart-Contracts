// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

/**
 * @author B00ste
 * @title DaoUtils
 * @custom:version 0.91
 */
contract DaoUtils {

  // --- GENERAL METHODS

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