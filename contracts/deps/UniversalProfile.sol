// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// LSP0ERC725Account
import {LSP0ERC725Account} from "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";

// LSP3Constants 
import {
  _LSP3_SUPPORTED_STANDARDS_KEY,
  _LSP3_SUPPORTED_STANDARDS_VALUE
} from "@lukso/lsp-smart-contracts/contracts/LSP3UniversalProfile/LSP3Constants.sol";

// LSP6Constants
import {
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY,
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX,
  _LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX
} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Constants.sol";

// Universal Receiver Constants
import {
  _LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY
} from "@lukso/lsp-smart-contracts/contracts/LSP1UniversalReceiver/LSP1Constants.sol";

// Multisig Constants
import {
  _MULTISIG_JSON_METADATA_KEY,
  _MULTISIG_QUORUM_KEY,

  _MULTISIG_PARTICIPANTS_ARRAY_KEY,
  _MULTISIG_PARTICIPANTS_ARRAY_PREFIX,
  _MULTISIG_PARTICIPANTS_MAPPING_PREFIX,
  _LSP6KEY_ADDRESSPERMISSIONS_MULTISIGPERMISSIONS_PREFIX
} from "../Multisig/MultisigConstants.sol";

// DAO Constants
import {
  _DAO_JSON_METDATA_KEY,
  _DAO_MAJORITY_KEY,
  _DAO_PARTICIPATION_RATE_KEY,
  _DAO_MINIMUM_VOTING_DELAY_KEY,
  _DAO_MINIMUM_VOTING_PERIOD_KEY,
  _DAO_MINIMUM_EXECUTION_DELAY_KEY,

  _DAO_PARTICIPANTS_ARRAY_KEY,
  _DAO_PARTICIPANTS_ARRAY_PREFIX,
  _DAO_PARTICIPANTS_MAPPING_PREFIX,
  _LSP6KEY_ADDRESSPERMISSIONS_DAOPERMISSIONS_PREFIX
} from "../Dao/DaoConstants.sol";

contract UniversalProfile is LSP0ERC725Account {

  /**
   * @dev Emits an event when receiving native tokens
   */
  receive() external payable virtual {
    if (msg.value > 0) emit ValueReceived(msg.sender, msg.value);
  }

  /**
   * @notice This constructor creates a new Universal Profile for the Dao and
   * sets all the data needed for intreactiong with a DAO, a Multisig or both.
   */
  constructor(
    address _newOwner,
    address _unviersalReceiverDelegateUPAddress
  ) LSP0ERC725Account(_newOwner) {

    bytes32[] memory keys = new bytes32[](2);
    bytes[] memory values = new bytes[](2);

    keys[0] = _LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY;
    values[0] = bytes.concat(bytes20(_unviersalReceiverDelegateUPAddress));

    keys[1] = _LSP3_SUPPORTED_STANDARDS_KEY;
    values[1] = _LSP3_SUPPORTED_STANDARDS_VALUE;

    setData(keys, values); 
  }

  /**
   * @notice Set DAO Metadata, Parameters, Participants and their Permissions
   */
  function setDaoData(
    bytes memory _JSONDaoMetdata,
    bytes32 _majority,
    bytes32 _participationRate,
    bytes32 _minimumVotingDelay,
    bytes32 _minimumVotingPeriod,
    bytes32 _minimumExecutionDelay,
    address[] memory _daoParticipants,
    bytes32[] memory _daoParticipantsPermissions
  ) external onlyOwner {
    require(
      _daoParticipants.length == _daoParticipantsPermissions.length
    );

    bytes32[] memory keys = new bytes32[](7 + (_daoParticipants.length * 3));
    bytes[] memory values = new bytes[](7 + (_daoParticipants.length * 3));

    // Setting DAO Metadata and Parameters
    keys[0] = _DAO_JSON_METDATA_KEY;
    values[0] = _JSONDaoMetdata;

    keys[1] = _DAO_MAJORITY_KEY;
    values[1] = bytes.concat(_majority);

    keys[2] = _DAO_PARTICIPATION_RATE_KEY;
    values[2] = bytes.concat(_participationRate);

    keys[3] = _DAO_MINIMUM_VOTING_DELAY_KEY;
    values[3] = bytes.concat(_minimumVotingDelay);

    keys[4] = _DAO_MINIMUM_VOTING_PERIOD_KEY;
    values[4] = bytes.concat(_minimumVotingPeriod);

    keys[5] = _DAO_MINIMUM_EXECUTION_DELAY_KEY;
    values[5] = bytes.concat(_minimumExecutionDelay);

    keys[6] = _DAO_PARTICIPANTS_ARRAY_KEY;
    values[6] = bytes.concat(bytes32(_daoParticipants.length));

    // Setting DAO Participants and their Permissions
    for (uint128 i = 0; i < _daoParticipants.length; i++) {
      keys[7 + i] = bytes32(bytes.concat(_DAO_PARTICIPANTS_ARRAY_PREFIX, bytes16(i)));
      values[7 + i] = bytes.concat(bytes20(_daoParticipants[i]));

      keys[7 + i + _daoParticipants.length] = bytes32(bytes.concat(_DAO_PARTICIPANTS_MAPPING_PREFIX, bytes20(_daoParticipants[i])));
      values[7 + i + _daoParticipants.length] = bytes.concat(bytes32(uint256(i)));

      keys[7 + i + (_daoParticipants.length * 2)] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_DAOPERMISSIONS_PREFIX, bytes20(_daoParticipants[i])));
      values[7 + i + (_daoParticipants.length * 2)] = bytes.concat(_daoParticipantsPermissions[i]);
    }

    setData(keys, values);
  }

  /**
   * @notice Set Multisig Metadata, Parameters, Participants and their Permissions
   */
  function setMultisigData(
    bytes memory _JSONMultisigMetdata,
    bytes1 quorum,
    address[] memory _multisigParticipants,
    bytes32[] memory _multisigParticipantsPermissions
  ) external onlyOwner {
    require(
      _multisigParticipantsPermissions.length == _multisigParticipantsPermissions.length
    );

    bytes32[] memory keys = new bytes32[](3 + (_multisigParticipants.length * 3));
    bytes[] memory values = new bytes[](3 + (_multisigParticipants.length * 3));

    // Setting Multisig Metadata and Parameters
    keys[0] = _MULTISIG_JSON_METADATA_KEY;
    values[0] = _JSONMultisigMetdata;

    keys[1] = _MULTISIG_QUORUM_KEY;
    values[1] = bytes.concat(quorum);

    keys[2] = _MULTISIG_PARTICIPANTS_ARRAY_KEY;
    values[2] = bytes.concat(bytes32(_multisigParticipants.length));

    // Setting Multisig Participants and their Permissions
    for (uint128 i = 0; i < _multisigParticipants.length; i++) {
      keys[3 + i] = bytes32(bytes.concat(_MULTISIG_PARTICIPANTS_ARRAY_PREFIX, bytes16(i)));
      values[3 + i] = bytes.concat(bytes20(_multisigParticipants[i]));

      keys[3 + _multisigParticipants.length + i] = bytes32(bytes.concat(_MULTISIG_PARTICIPANTS_MAPPING_PREFIX, bytes20(_multisigParticipants[i])));
      values[3 + _multisigParticipants.length + i] = bytes.concat(bytes32(uint256(i)));

      keys[3 + (_multisigParticipants.length * 2) + i] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_MULTISIGPERMISSIONS_PREFIX, bytes20(_multisigParticipants[i])));
      values[3 + (_multisigParticipants.length * 2) + i] = bytes.concat(_multisigParticipantsPermissions[i]);
    }

    setData(keys, values);
  }

  function setControllerPermissionsForMultisig(address _multisigAddress) external onlyOwner {
    bytes32[] memory keys = new bytes32[](3);
    bytes[] memory values = new bytes[](3);

    bytes memory encodedArrayLength = getData(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY);
    uint256 oldArraylength = uint256(bytes32(encodedArrayLength));
    uint256 newArrayLength = oldArraylength + 1;

    keys[0] = _LSP6KEY_ADDRESSPERMISSIONS_ARRAY;
    values[0] = bytes.concat(bytes32(newArrayLength));

    keys[1] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(uint128(oldArraylength))));
    values[1] = bytes.concat(bytes20(_multisigAddress));

    keys[2] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX, bytes20(_multisigAddress)));
    values[2] = bytes.concat(bytes32(0x0000000000000000000000000000000000000000000000000000000000007fbf));

    setData(keys, values);
  }

  function setControllerPermissionsForDao(
    address _daoPermissions,
    address _daoDelegates,
    address _daoProposals
  )
    external
    onlyOwner
  {
    bytes32[] memory keys = new bytes32[](7);
    bytes[] memory values = new bytes[](7);

    bytes memory encodedArrayLength = getData(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY);
    uint256 oldArraylength = uint256(bytes32(encodedArrayLength));
    uint256 newArrayLength = oldArraylength + 3;

    keys[0] = _LSP6KEY_ADDRESSPERMISSIONS_ARRAY;
    values[0] = bytes.concat(bytes32(uint256(newArrayLength)));

    keys[1] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(uint128(oldArraylength))));
    values[1] = bytes.concat(bytes20(_daoPermissions));

    keys[2] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(uint128(oldArraylength + 1))));
    values[2] = bytes.concat(bytes20(_daoDelegates));

    keys[3] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(uint128(oldArraylength + 2))));
    values[3] = bytes.concat(bytes20(_daoProposals));

    keys[4] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX, bytes20(_daoPermissions)));
    values[4] = bytes.concat(bytes32(0x0000000000000000000000000000000000000000000000000000000000007fbf));

    keys[5] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX, bytes20(_daoDelegates)));
    values[5] = bytes.concat(bytes32(0x0000000000000000000000000000000000000000000000000000000000007fbf));

    keys[6] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX, bytes20(_daoProposals)));
    values[6] = bytes.concat(bytes32(0x0000000000000000000000000000000000000000000000000000000000007fbf));

    setData(keys, values);
  }

  function giveOwnerPermissionToChangeOwner() external onlyOwner {
    bytes32[] memory keys = new bytes32[](3);
    bytes[] memory values = new bytes[](3);

    bytes memory encodedArrayLength = getData(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY);
    uint256 oldArraylength = uint256(bytes32(encodedArrayLength));
    uint256 newArrayLength = oldArraylength + 1;
    address ownerAddress = owner();

    keys[0] = _LSP6KEY_ADDRESSPERMISSIONS_ARRAY;
    values[0] = bytes.concat(bytes32(uint256(newArrayLength)));

    keys[1] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(uint128(oldArraylength))));
    values[1] = bytes.concat(bytes20(ownerAddress));

    keys[2] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX, bytes20(ownerAddress)));
    values[2] = bytes.concat(bytes32(0x0000000000000000000000000000000000000000000000000000000000000001));

    setData(keys, values);
  }

}