// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;

// DaoPermissions
import {DaoProposals} from "../../../Dao/DaoProposals.sol";

// Interface
import {IDaoProposalsDeployer} from "./IDaoProposalsDeployer.sol";

contract DaoProposalsDeployer is IDaoProposalsDeployer {

  function deployDaoProposals(
    address payable _UNIVERSAL_PROFILE,
    address _KEY_MANAGER
  )
    external
    returns (address _DAO_PROPOSALS)
  {
    _DAO_PROPOSALS = address(
      new DaoProposals(
        _UNIVERSAL_PROFILE,
        _KEY_MANAGER
      )
    );
  }

}