// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {LSP0ERC725Account} from "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
import {LSP6KeyManager} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6KeyManager.sol";
import {DaoKeyManager} from "./DaoAccount/DaoKeyManager.sol";
import {VaultKeyManager} from "./DaoVault/VaultKeyManager.sol";
import {
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY,
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX,
  _LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX
} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Constants.sol";

/**
 *
* @notice This smart contract is responsible for creating an connecting every
* LEGO block needed for a working DAO suitable for the user.
 *
 * @author B00ste
 * @title DaoCreator
 * @custom:version 0.92
 */
contract DaoCreator {

  /**
   * @notice Structure for saving user progress in DAO creation.
   */
  struct UserProgress {
    address payable UNIVERSAL_PROFILE;
    address KEY_MANAGER;
    address DAO_KEY_MANAGER;
    address VAULT_KEY_MANAGER;

    // Up to 16 phases for creating a DAO.
    bytes2 phases;
  }

  /**
   * @notice Mapping for storing user progress.
   */
  mapping (address => UserProgress) userProgress;
  
  /**
   * @notice Create the Universal Profile for the DAO.
   */
  function createUniversalProfile() external {
    require(
      (uint16(userProgress[msg.sender].phases)) & (1 << 0) == 0,
      "Universal Profile is already initialized."
    );
    userProgress[msg.sender].UNIVERSAL_PROFILE = payable(new LSP0ERC725Account(address(this)));
    userProgress[msg.sender].phases = bytes2(uint16(1));
  }

  /**
   * @notice Create the Key Manager of the Universal Profile
   */
  function createUniversalProfileKeyManager() external {
    require(
      (uint16(userProgress[msg.sender].phases)) & (1 << 0) != 0 &&
      (uint16(userProgress[msg.sender].phases)) & (1 << 1) == 0,
      "Universal profile not initialized or Universal Profile Key manager already initialized."
    );
    userProgress[msg.sender].KEY_MANAGER = address(new LSP6KeyManager(userProgress[msg.sender].UNIVERSAL_PROFILE));
    userProgress[msg.sender].phases = bytes2(uint16(userProgress[msg.sender].phases) << 1);
  }

  /**
   * @notice Create the DAO Key manager.
   */
  function createDaoKeyManager() external {
    require(
      (uint16(userProgress[msg.sender].phases)) & (1 << 1) != 0 &&
      (uint16(userProgress[msg.sender].phases)) & (1 << 2) == 0,
      "Universal Profile Key Manager not initialized or DAO Key Manager already initialized."
    );
    userProgress[msg.sender].DAO_KEY_MANAGER = address(new DaoKeyManager(
      userProgress[msg.sender].UNIVERSAL_PROFILE,
      userProgress[msg.sender].KEY_MANAGER
    ));
    userProgress[msg.sender].phases = bytes2(uint16(userProgress[msg.sender].phases) << 1);
  }

  /**
   * @notice Create Vault Key Manager.
   */
  function createVaultKeyManager() external {
    require(
      (uint16(userProgress[msg.sender].phases)) & (1 << 2) != 0 &&
      (uint16(userProgress[msg.sender].phases)) & (1 << 3) == 0,
      "DAO Key Manager not initialized or Vault Key Manager already initialized."
    );
    userProgress[msg.sender].VAULT_KEY_MANAGER = address(new VaultKeyManager());
    userProgress[msg.sender].phases = bytes2(uint16(userProgress[msg.sender].phases) << 1);
  }

  /**
   * @notice Give 7FFF permissions to DaoKeyManager and to VaultKeyManager.
   */
  function giveMaxPermissionsToDaoAndVault() external {
    require(
      (uint16(userProgress[msg.sender].phases)) & (1 << 3) != 0 &&
      (uint16(userProgress[msg.sender].phases)) & (1 << 4) == 0,
      "Vault Key Manager not initialized or permissions already given."
    );
    bytes32[] memory keys = new bytes32[](7);
    keys[0] = _LSP6KEY_ADDRESSPERMISSIONS_ARRAY;
    keys[1] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(0)));
    keys[2] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(uint128(1))));
    keys[3] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(uint128(2))));
    keys[4] = bytes32(bytes.concat(
      _LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX,
      bytes20(userProgress[msg.sender].DAO_KEY_MANAGER)
    ));
    keys[5] = bytes32(bytes.concat(
      _LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX,
      bytes20(userProgress[msg.sender].VAULT_KEY_MANAGER)
    ));
    keys[6] = bytes32(bytes.concat(
      _LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX,
      bytes20(address(this))
    ));
    bytes[] memory values = new bytes[](7);
    values[0] = bytes.concat(bytes32(uint256(2)));
    values[1] = bytes.concat(bytes20(userProgress[msg.sender].DAO_KEY_MANAGER));
    values[2] = bytes.concat(bytes20(userProgress[msg.sender].VAULT_KEY_MANAGER));
    values[3] = bytes.concat(bytes20(address(this)));
    values[4] = bytes.concat(bytes32(0x0000000000000000000000000000000000000000000000000000000000007FFF));
    values[5] = bytes.concat(bytes32(0x0000000000000000000000000000000000000000000000000000000000007FFF));
    values[6] = bytes.concat(bytes32(0x0000000000000000000000000000000000000000000000000000000000000001));

    LSP0ERC725Account(userProgress[msg.sender].UNIVERSAL_PROFILE).setData(
      keys, values
    );
    userProgress[msg.sender].phases = bytes2(uint16(userProgress[msg.sender].phases) << 1);
  }

  /**
   * @notice transferOwnership() from UNIVERSAL_PROFILE to KEY_MANAGER
   * and claimOwnership() of UNIVERSAL_PROFILE from KEY_MANAGER.
   */
  function transferOwnership() external {
    require(
      (uint16(userProgress[msg.sender].phases)) & (1 << 4) != 0 &&
      (uint16(userProgress[msg.sender].phases)) & (1 << 5) == 0,
      "Permissions not given or Ownership already transfered."
    );
    LSP0ERC725Account(userProgress[msg.sender].UNIVERSAL_PROFILE).transferOwnership(
      userProgress[msg.sender].KEY_MANAGER
    );
    LSP6KeyManager(userProgress[msg.sender].KEY_MANAGER).execute(
      abi.encodeWithSelector(bytes4(keccak256("claimOwnership()")))
    );
    userProgress[msg.sender].phases = bytes2(uint16(userProgress[msg.sender].phases) << 1);
  }

}