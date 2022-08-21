// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;

// DaoPermissions
import {DaoPermissions} from "../../../Dao/DaoPermissions.sol";

// Interface
import {IDaoPermissionsDeployer} from "./IDaoPermissionsDeployer.sol";

contract DaoPermissionsDeployer is IDaoPermissionsDeployer {

  function deployDaoPermissions(
    address payable _UNIVERSAL_PROFILE,
    address _KEY_MANAGER
  )
    external
    returns (address _DAO_PERMISSIONS)
  {
    _DAO_PERMISSIONS = address(
      new DaoPermissions(
        _UNIVERSAL_PROFILE,
        _KEY_MANAGER
      )
    );
  }

}