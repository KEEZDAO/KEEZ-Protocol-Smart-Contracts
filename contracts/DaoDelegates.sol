// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";

/**
 * @author B00ste
 * @title DaoDelegates
 * @custom:version 0.7
 */
contract DaoDelegates {

  /**
   * @notice Instance of the DAO key manager.
   */
  LSP0ERC725Account private DAO;

  constructor(LSP0ERC725Account _DAO) {
    DAO = _DAO;
  }

  /**
   * @notice Delegate vote to an address.
   */
  function _setDelegatee(address delegator, address delegatee) internal {
    bytes32 voteDelegateeKey = bytes32(bytes.concat(
      bytes6(keccak256("SingleDelegatee")),
      bytes4(keccak256("Delegatee")),
      bytes2(0),
      bytes20(delegator)
    ));
    bytes memory voteDelegatee = bytes.concat(bytes20(delegatee));
    DAO.setData(voteDelegateeKey, voteDelegatee);
  }

  /**
   * @notice Get delegatee of an Universal Profile
   */
  function _getDelegatee(address delegator) internal view returns(address delegatee) {
    bytes32 voteDelegateeKey = bytes32(bytes.concat(
      bytes6(keccak256("SingleDelegatee")),
      bytes4(keccak256("Delegatee")),
      bytes2(0),
      bytes20(delegator)
    ));
    delegatee = address(bytes20(DAO.getData(voteDelegateeKey)));
  }
  
}