// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
import "./DaoPermissions.sol";
import "./DaoProposals.sol";
import "./DaoDelegates.sol";

/**
 *
* @notice This smart contract is responsible for connecting all the necessary tools for
* a DAO based on Universal Profiles (LSP0ERC725Account)
 *
 * @author B00ste
 * @title DaoAccount
 * @custom:version 0.8
 */
contract DaoAccount is DaoPermissions, DaoProposals, DaoDelegates {
   
  /**
   * @notice Unique instance of the DAO Universal Profile.
   */
  LSP0ERC725Account private DAO = new LSP0ERC725Account(address(this));

  /**
   * @notice Instance for the utils of a Universal Profile DAO.
   */
  DaoUtils private utils = new DaoUtils();

  /**
   * @notice Initialization of the Universal Profile Account as a DAO Account;
   * This smart contract will be given all controller permissions.
   * Here is where all the tools needed for a functioning DAO are initialized.
   *
   * @param _quorum The percentage of pro votes from the sum of pro and against votes needed for a proposal to pass.
   * @param _participationRate The percentage of pro and against votes compared to abstain votes needed for a proposal to pass.
   * @param _votingDelay Time required to pass before a proposal goes to the voting phase.
   * @param _votingPeriod Time allowed for voting on a proposal.
   */
  constructor(
    uint8 _quorum,
    uint8 _participationRate,
    uint256 _votingDelay,
    uint256 _votingPeriod
  )
    DaoPermissions(DAO, utils)
    DaoProposals(
      _quorum,
      _participationRate,
      _votingDelay,
      _votingPeriod,
      DAO,
      utils,
      address(this)
    )
    DaoDelegates(DAO, utils)
  {

    _setDaoAddressesArrayLength(0);
    _setProposalsArrayLength(0, 1);
    _setProposalsArrayLength(0, 2);
    _setProposalsArrayLength(0, 3);

    bytes32[] memory keysArray = new bytes32[](3);
    // Controller addresses array key
    keysArray[0] = bytes32(0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3);
    // First element from controller addresses array key
    keysArray[1] = bytes32(bytes.concat(bytes16(0xdf30dba06db6a30e65354d9a64c60986), bytes16(0)));
    // This addresses permissions key
    keysArray[2] = bytes32(bytes.concat(bytes12(0x4b80742de2bf82acb3630000), bytes20(address(this))));


    bytes[] memory valuesArray = new bytes[](3);
    // Controller addresses array value
    valuesArray[0] = bytes.concat(bytes32(uint256(1)));
    // First element from controller addresses array value
    valuesArray[1] = bytes.concat(bytes20(address(this)));
    // This addresses permissions value
    valuesArray[2] = bytes.concat(bytes32(0x0000000000000000000000000000000000000000000000000000000000007FFF));

    DAO.setData(keysArray, valuesArray);
  }

  // --- MODIFIERS

  /**
   * @notice Verifies if an Universal Profile has EXECUTE permission.
   */
  modifier hasExecutePermission(address universalProfileAddress) {
    bytes memory addressPermissions = _getAddressDaoPermission(universalProfileAddress);
    require(
      (uint256(bytes32(addressPermissions)) & (1 << 4) == 16),
      "This address doesn't have EXECUTE permission."
    );
    _;
  }

}