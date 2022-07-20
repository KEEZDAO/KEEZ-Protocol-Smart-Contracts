// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";

/**
 *
* @notice This smart contract is responsible for the permissions for the Multisig.
 *
 * @author B00ste
 * @title MultisigPermissions
 * @custom:version 0.1
 */

 contract MultisigPermissions {

  /**
   * @notice Unique instance of the MULTISIG Universal Profile.
   */
  LSP0ERC725Account private MULTISIG;

  constructor(LSP0ERC725Account _MULTISIG) {
    MULTISIG = _MULTISIG;
  }

 }