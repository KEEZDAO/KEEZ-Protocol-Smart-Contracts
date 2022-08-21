// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;

import {LSP1UniversalReceiverDelegateVault} from "@lukso/lsp-smart-contracts/contracts/LSP1UniversalReceiver/LSP1UniversalReceiverDelegateVault/LSP1UniversalReceiverDelegateVault.sol";

contract UniversalReceiverDelegateVault is LSP1UniversalReceiverDelegateVault {

  /**
    * @inheritdoc LSP1UniversalReceiverDelegateVault
    */
  function universalReceiverDelegate(
    address sender,
    uint256 value,
    bytes32 typeId,
    bytes memory data
  ) public virtual override returns (bytes memory result) {
    
    /**
     * TODO verify the received token address is part of allowed tokens to be received.
     */

    result = super.universalReceiverDelegate(sender, value, typeId, data);
  }

}  