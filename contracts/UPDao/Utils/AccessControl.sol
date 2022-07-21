// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import "./DaoUtils.sol";

contract AccessControl {

  /**
   * @notice Instance for the utils of a Universal Profile DAO.
   */
  DaoUtils private utils;

  /**
   * @notice Instance for the DAO permissions.
   */
  address private DAO_ADDRESS;

  /**
   * @notice Initializing the contract.
   */
  bool internal initialized = false;
  function initAccessControl(DaoUtils _utils, address daoAddress) internal {
    require(!initialized, "The contract is already initialized.");
    utils = _utils;
    DAO_ADDRESS = daoAddress;
    initialized = true;
  }

  modifier isInitialized() {
    require(
      initialized,
      "Contracts are not initialized."
    );
    _;
  }

  modifier isNotInitialized() {
    require(
      !initialized,
      "Contracts are initialized."
    );
    _;
  }

  /**
   * @notice Verify that the message sender is the Dao Universal Profile Account
   */
  modifier isDao(address msgSender) {
    require(
      msgSender == DAO_ADDRESS,
      "Caller is not the DAO."
    );
    _;
  }

  /**
   * @notice Verify if an address is a controller address.
   */
  modifier isControllerAddress(address universalProfileAddress) {
    IERC725Y UP = IERC725Y(universalProfileAddress);
    bytes32 controllersArraykey = bytes32(0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3);
    bytes memory controllersArray = UP.getData(controllersArraykey);
    bool verifyControllerAddress = false;
    for (uint128 i = 0; i < uint256(bytes32(controllersArray)); i++) {
      bytes32 addressKey = bytes32(bytes.concat(
        utils._bytes32ToTwoHalfs(controllersArraykey)[0],
        bytes16(i)
      ));
      if (bytes20(msg.sender) == bytes20(UP.getData(addressKey))) {
        verifyControllerAddress = true;
      }
    }
    require(
      verifyControllerAddress,
      "The message sender is not a controller address."
    );
    _;
  }

}