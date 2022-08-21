// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;

interface IDaoDelegatesDeployer {

  function deployDaoDelegates(
    address payable _UNIVERSAL_PROFILE,
    address _KEY_MANAGER
  ) external returns (address _DAO_DELEGATES);

}