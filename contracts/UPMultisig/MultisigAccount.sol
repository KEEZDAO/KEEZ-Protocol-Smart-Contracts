// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
import "./MultisigPermissions.sol";

/**
 *
* @notice This smart contract is responsible for creating a Universal Profile Account based Multisig.
 *
 * @author B00ste
 * @title MultisigAccount
 * @custom:version 0.1
 */

 contract MultisigAccount is MultisigPermissions {
   
  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId)
    public
    pure
    returns (bool)
  {
    return interfaceId == bytes4(keccak256("UniversalProfileMultisigAccount"));
  }

  /**
   * @notice Unique instance of the MULTISIG Universal Profile.
   */
  LSP0ERC725Account private MULTISIG = new LSP0ERC725Account(address(this));

  constructor(
    address[] memory multisigUsers
  )
    MultisigPermissions(MULTISIG)
  {
    
  }

 }