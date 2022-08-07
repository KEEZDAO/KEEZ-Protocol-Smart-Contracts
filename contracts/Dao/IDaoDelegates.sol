// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

/**
 * @author B00ste
 * @title IDaoDelegates
 * @custom:version 1
 */
interface IDaoDelegates {

  /**
   * @notice Delegate your vote.
   */
  function delegate(address delegatee) external;

  /**
   * @notice a
   */
  function changeDelegate(address newDelegatee) external;

  /**
   * @notice a
   */
  function undelegate() external;
  
}