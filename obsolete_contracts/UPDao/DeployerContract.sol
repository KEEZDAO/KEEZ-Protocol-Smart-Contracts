// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {LSP0ERC725Account} from "./LSP0ERC725Account.sol";
import {LSP6KeyManager} from "./LSP6KeyManager.sol";
import {DaoAccount} from "./DaoAccount.sol";
import {DaoAccountMetadata} from "./DaoAccountMetadata.sol";
import {DaoPermissions} from "./DaoPermissions.sol";
import {DaoProposals} from "./DaoProposals.sol";
import {DaoDelegates} from "./DaoDelegates.sol";
import {DaoParticipation} from "./DaoParticipation.sol";
import {DaoVotingStrategies} from "./DaoVotingStrategies.sol";
import {
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY,
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX,
  _LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX,
  _PERMISSION_SETDATA
} from "./Utils/DaoConstants.sol";

/**
 *
* @notice This smart contract is responsible for deploying and connecting all
* the necessary components for a Universal Profile DAO to work.
 *
 * @author B00ste
 * @title DeployerContract
 * @custom:version 0.92
 */
contract DeployerContract {

  /**
   * @notice Structure for saving all the data a user is creating using this contract.
   */
  struct UserProgress {
    address UNIVERSAL_PROFILE;
    address KEY_MANAGER;
    address DAO_METADATA;
    address DAO_PERMISSIONS;
    address DAO_PROPOSALS;
    address DAO_DELEGATES;
    address DAO_PARTICIPATION;
    address DAO_VOTING_STRATEGIES;
    address DAO_ACCOUNT;
    bytes2 phases;
  }

  /**
   * @notice Mapping for saving the DAO creations of users and storing progress.
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
    userProgress[msg.sender].UNIVERSAL_PROFILE = address(new LSP0ERC725Account(address(this)));
    userProgress[msg.sender].phases = bytes2(0x0001);
  }

  /**
   * @notice Create the Key Manager for the DAO.
   */
  function createKeyManager() external {
    require(
      (uint16(userProgress[msg.sender].phases)) & (1 << 0) != 0 &&
      (uint16(userProgress[msg.sender].phases)) & (1 << 1) == 0,
      "Universal Profile not initialized or Key Manager already initialized."
    );
    userProgress[msg.sender].KEY_MANAGER = address(new LSP6KeyManager(address(userProgress[msg.sender].UNIVERSAL_PROFILE)));
    userProgress[msg.sender].phases = bytes2(0x0003);
  }

  /**
   * @notice Create the tools for a DAO Account.
   */
  function createDaoAccountTools() external {
    require(
      (uint16(userProgress[msg.sender].phases)) & (1 << 1) != 0 &&
      (uint16(userProgress[msg.sender].phases)) & (1 << 2) == 0,
      "Key Manager is not initialized or Dao Account Tools already initialized."
    );
    userProgress[msg.sender].DAO_METADATA = address(new DaoAccountMetadata());
    userProgress[msg.sender].DAO_PERMISSIONS = address(new DaoPermissions());
    userProgress[msg.sender].DAO_PROPOSALS = address(new DaoProposals());
    userProgress[msg.sender].DAO_DELEGATES = address(new DaoDelegates());
    userProgress[msg.sender].DAO_PARTICIPATION = address(new DaoParticipation());
    userProgress[msg.sender].DAO_VOTING_STRATEGIES = address(new DaoVotingStrategies());
    userProgress[msg.sender].phases = bytes2(0x0007);
  }

  /**
   * @notice Create the DAO Account.
   */
  function createDaoAccount() external {
    require(
      (uint16(userProgress[msg.sender].phases)) & (1 << 2) != 0 &&
      (uint16(userProgress[msg.sender].phases)) & (1 << 3) == 0,
      "Dao Account Tools not initialized or Dao Account already initialized."
    );
    userProgress[msg.sender].DAO_ACCOUNT = address(new DaoAccount(
      userProgress[msg.sender].UNIVERSAL_PROFILE,
      userProgress[msg.sender].KEY_MANAGER,
      userProgress[msg.sender].DAO_METADATA,
      userProgress[msg.sender].DAO_PERMISSIONS,
      userProgress[msg.sender].DAO_PROPOSALS,
      userProgress[msg.sender].DAO_DELEGATES,
      userProgress[msg.sender].DAO_PARTICIPATION,
      userProgress[msg.sender].DAO_VOTING_STRATEGIES
    ));
    userProgress[msg.sender].phases = bytes2(0x000F);
  }

  /**
   * @notice Set the necessary permissions for the Dao Tools and Dao Account.
   */
  function setPermissions() external {
    require(
      (uint16(userProgress[msg.sender].phases)) & (1 << 3) != 0 &&
      (uint16(userProgress[msg.sender].phases)) & (1 << 4) == 0,
      "Dao Account not initialized or permissions alerady set."
    );
    bytes32[] memory keysArray = new bytes32[](11);
    keysArray[0] = bytes32(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY);
    keysArray[1] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(0)));
    keysArray[2] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(uint128(1))));
    keysArray[3] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(uint128(2))));
    keysArray[4] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(uint128(3))));
    keysArray[5] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(uint128(4))));
    keysArray[6] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX, bytes20(address(userProgress[msg.sender].DAO_ACCOUNT))));
    keysArray[7] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX, bytes20(address(userProgress[msg.sender].DAO_METADATA))));
    keysArray[8] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX, bytes20(address(userProgress[msg.sender].DAO_PERMISSIONS))));
    keysArray[9] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX, bytes20(address(userProgress[msg.sender].DAO_PROPOSALS))));
    keysArray[10] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX, bytes20(address(userProgress[msg.sender].DAO_DELEGATES))));


    bytes[] memory valuesArray = new bytes[](11);
    valuesArray[0] = bytes.concat(bytes32(uint256(5)));
    valuesArray[1] = bytes.concat(bytes20(address(userProgress[msg.sender].DAO_ACCOUNT)));
    valuesArray[2] = bytes.concat(bytes20(address(userProgress[msg.sender].DAO_METADATA)));
    valuesArray[3] = bytes.concat(bytes20(address(userProgress[msg.sender].DAO_PERMISSIONS)));
    valuesArray[4] = bytes.concat(bytes20(address(userProgress[msg.sender].DAO_PROPOSALS)));
    valuesArray[5] = bytes.concat(bytes20(address(userProgress[msg.sender].DAO_DELEGATES)));
    valuesArray[6] = bytes.concat(bytes32(0x0000000000000000000000000000000000000000000000000000000000007FFF));
    valuesArray[7] = bytes.concat(bytes32(_PERMISSION_SETDATA));
    valuesArray[8] = bytes.concat(bytes32(_PERMISSION_SETDATA));
    valuesArray[9] = bytes.concat(bytes32(_PERMISSION_SETDATA));
    valuesArray[10] = bytes.concat(bytes32(_PERMISSION_SETDATA));

    LSP0ERC725Account(userProgress[msg.sender].UNIVERSAL_PROFILE).setData(keysArray, valuesArray);
    userProgress[msg.sender].phases = bytes2(0x001F);
  }

  /**
   * @notice Transfer Universal Profile ownership to Key Manager.
   */
  function transferOwnersipToKeyManager() external {
    require(
      (uint16(userProgress[msg.sender].phases)) & (1 << 4) != 0 &&
      (uint16(userProgress[msg.sender].phases)) & (1 << 5) == 0,
      "The permissions are not set yet or Ownership is already transfered."
    );
    LSP0ERC725Account(userProgress[msg.sender].UNIVERSAL_PROFILE).transferOwnership(
      address(userProgress[msg.sender].KEY_MANAGER)
    );
    LSP6KeyManager(userProgress[msg.sender].KEY_MANAGER).getOwnership();
    userProgress[msg.sender].phases = bytes2(0x003F);
  }
  
  /**
   * @notice Initialize the metadata of the DAO. Important data.
   *
   * @param name Name of the DAO.
   * @param description Description of the DAO.
   * @param majority The percentage of pro votes from the sum of pro and against votes needed for a proposal to pass.
   * @param participationRate The percentage of pro and against votes compared to abstain votes needed for a proposal to pass.
   * @param votingDelay Time required to pass before a proposal goes to the voting phase.
   * @param votingPeriod Time allowed for voting on a proposal.
   */
  function initializeDaoAccount(
    string memory name,
    string memory description,
    uint8 majority,
    uint8 participationRate,
    uint256 votingDelay,
    uint256 votingPeriod
  ) public {
    require(
      (uint16(userProgress[msg.sender].phases)) & (1 << 5) != 0 &&
      (uint16(userProgress[msg.sender].phases)) & (1 << 6) == 0,
      "Ownership not trasfered yet or Dao Account already initialized."
    );
    require(majority >= 0 && majority <= 100);
    require(participationRate >= 0 && participationRate <= 100);
    DaoAccountMetadata(userProgress[msg.sender].DAO_METADATA)._setDaoName(name);
    DaoAccountMetadata(userProgress[msg.sender].DAO_METADATA)._setDaoDescription(description);
    DaoAccountMetadata(userProgress[msg.sender].DAO_METADATA)._setDaoMajority(majority);
    DaoAccountMetadata(userProgress[msg.sender].DAO_METADATA)._setDaoParticipationRate(participationRate);
    DaoAccountMetadata(userProgress[msg.sender].DAO_METADATA)._setDaoVotingDelay(votingDelay);
    DaoAccountMetadata(userProgress[msg.sender].DAO_METADATA)._setDaoVotingPeriod(votingPeriod);
    userProgress[msg.sender].phases = bytes2(0x007F);
  }

}