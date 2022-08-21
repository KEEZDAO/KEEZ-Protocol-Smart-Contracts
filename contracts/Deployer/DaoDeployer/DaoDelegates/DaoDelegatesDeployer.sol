// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;

// DaoPermissions
import {DaoDelegates} from "../../../Dao/DaoDelegates.sol";

// Interface
import {IDaoDelegatesDeployer} from "./IDaoDelegatesDeployer.sol";

contract DaoDelegatesDeployer is IDaoDelegatesDeployer {

  function deployDaoDelegates(
    address payable _UNIVERSAL_PROFILE,
    address _KEY_MANAGER
  )
    external
    returns (address _DAO_DELEGATES)
  {
    _DAO_DELEGATES = address(
      new DaoDelegates(
        _UNIVERSAL_PROFILE,
        _KEY_MANAGER
      )
    );
  }

}