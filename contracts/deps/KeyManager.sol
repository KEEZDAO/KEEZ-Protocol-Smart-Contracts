// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;

import {LSP6KeyManager} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6KeyManager.sol";

contract KeyManager is LSP6KeyManager {

  constructor(address target_) LSP6KeyManager(target_) {}

}