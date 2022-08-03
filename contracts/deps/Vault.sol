// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// LSP9Vault
import {LSP9Vault} from "@lukso/lsp-smart-contracts/contracts/LSP9Vault/LSP9Vault.sol";

// Universal Receiver Constants
import {
  _LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY
} from "@lukso/lsp-smart-contracts/contracts/LSP1UniversalReceiver/LSP1Constants.sol";

contract Vault is LSP9Vault {

  /**
   * @dev Emits an event when receiving native tokens
   */
  receive() external payable virtual {
    if (msg.value > 0) emit ValueReceived(msg.sender, msg.value);
  }

  constructor(
    address newOwner,
    address _unviersalReceiverDelegateVaultAddress
  ) LSP9Vault(newOwner) {

    setData(
      _LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY,
      bytes.concat(bytes20(_unviersalReceiverDelegateVaultAddress))
    );

  }

  /**
   * TODO override execute(...) so you could check that the caller has
   * specific permissions for calling certain functions.
   */

}