// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;

// setData(bytes32[],bytes[]) & getData(bytes32[])
import {IDeployer} from "../IDeployer.sol";

// getData(bytes32)
import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

// DAO Deployers
import {IDaoPermissionsDeployer} from "./DaoPermissions/IDaoPermissionsDeployer.sol";
import {IDaoDelegatesDeployer} from "./DaoDelegates/IDaoDelegatesDeployer.sol";
import {IDaoProposalsDeployer} from "./DaoProposals/IDaoProposalsDeployer.sol";

// LSP6Constants
import {
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY,
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX,
  _LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX
} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Constants.sol";

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
} from "../../Dao/DaoConstants.sol";

// Interface
import {IDaoDeployer} from "./IDaoDeployer.sol";

contract DaoDeployer is IDaoDeployer {
  /**
   * @dev Address of DAO Permissions deployer.
   */
  address private DAO_PERMSISSIONS;
  /**
   * @dev Address of DAO Delegates deployer.
   */
  address private DAO_DELEGATES;
  /**
   * @dev Address of DAO Proposals deployer.
   */
  address private DAO_PROPOSALS;

  constructor (
    address _DAO_PERMSISSIONS,
    address _DAO_DELEGATES,
    address _DAO_PROPOSALS  
  ) { 
    DAO_PERMSISSIONS = _DAO_PERMSISSIONS;
    DAO_DELEGATES = _DAO_DELEGATES;
    DAO_PROPOSALS = _DAO_PROPOSALS;
  }

  /**
   * @inheritdoc IDaoDeployer
   */
  function deployDao(
    address payable _UNIVERSAL_PROFILE,
    address _KEY_MANAGER,
    address _caller,

    bytes memory _JSONDaoMetdata,
    bytes32 _majority,
    bytes32 _participationRate,
    bytes32 _minimumVotingDelay,
    bytes32 _minimumVotingPeriod,
    bytes32 _minimumExecutionDelay,
    address[] memory _daoParticipants,
    bytes32[] memory _daoParticipantsPermissions
  )
    external
    returns(address[] memory _DAO_ADDRESSES)
  {
    _DAO_ADDRESSES = new address[](3);
    _DAO_ADDRESSES[0] = IDaoPermissionsDeployer(DAO_PERMSISSIONS).deployDaoPermissions(_UNIVERSAL_PROFILE, _KEY_MANAGER);
    _DAO_ADDRESSES[1] = IDaoDelegatesDeployer(DAO_DELEGATES).deployDaoDelegates(_UNIVERSAL_PROFILE, _KEY_MANAGER);
    _DAO_ADDRESSES[2] = IDaoProposalsDeployer(DAO_PROPOSALS).deployDaoProposals(_UNIVERSAL_PROFILE, _KEY_MANAGER);
    emit NewDaoDeployed(
      _DAO_ADDRESSES[0],
      _DAO_ADDRESSES[1],
      _DAO_ADDRESSES[2]
    );
    setDaoPermissions(
      _UNIVERSAL_PROFILE,
      _DAO_ADDRESSES[0],
      _DAO_ADDRESSES[1],
      _DAO_ADDRESSES[2],
      _caller
    );

    setDaoSettings(
      _caller,
      _JSONDaoMetdata,
      _majority,
      _participationRate,
      _minimumVotingDelay,
      _minimumVotingPeriod,
      _minimumExecutionDelay,
      _daoParticipants,
      _daoParticipantsPermissions
    );
  }

  /**
   * @dev Update the permissions of the Universal Profile that controls the Dao.
   */
  function setDaoPermissions(
    address _UNIVERSAL_PROFILE,
    address _daoPermissions,
    address _daoDelegates,
    address _daoProposals,
    address _caller
  )
    internal
  {
    bytes32[] memory keys = new bytes32[](7);
    bytes[] memory values = new bytes[](7);

    bytes memory encodedArrayLength = IERC725Y(_UNIVERSAL_PROFILE).getData(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY);
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

    IDeployer(msg.sender).setData(_caller, keys, values);
  }

  /**
   * @dev Set the DAO settings.
   */
  function setDaoSettings(
    address _caller,
    bytes memory _JSONDaoMetdata,
    bytes32 _majority,
    bytes32 _participationRate,
    bytes32 _minimumVotingDelay,
    bytes32 _minimumVotingPeriod,
    bytes32 _minimumExecutionDelay,
    address[] memory _daoParticipants,
    bytes32[] memory _daoParticipantsPermissions
  )
    internal
  {
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

    IDeployer(msg.sender).setData(_caller, keys, values);
  }

}