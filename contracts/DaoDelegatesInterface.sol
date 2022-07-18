// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface DaoDelegatesInterface {

  function _getDelegateeOfTheDelegator(address delegator) external view returns(address delegatee);
  
  function _getDelegatorsArrayLength(address delegatee) external view returns(uint256 length);

  function _getDelegatorByIndex(address delegatee, uint256 index) external view returns(address delegator);
  
}