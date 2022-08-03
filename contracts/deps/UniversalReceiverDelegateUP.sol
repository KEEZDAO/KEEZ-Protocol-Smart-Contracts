// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import {LSP1UniversalReceiverDelegateUP} from "@lukso/lsp-smart-contracts/contracts/LSP1UniversalReceiver/LSP1UniversalReceiverDelegateUP/LSP1UniversalReceiverDelegateUP.sol";

contract UniversalReceiverDelegateUP is LSP1UniversalReceiverDelegateUP {

  /**
    * @inheritdoc LSP1UniversalReceiverDelegateUP
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