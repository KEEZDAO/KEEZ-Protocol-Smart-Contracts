// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import {ILSP6KeyManager} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/ILSP6KeyManager.sol";
import {IDaoKeyManager} from "./IDaoKeyManager.sol";
import {
  NoPermissionsSet,
  NotAuthorised
} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Errors.sol";
import {
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY,
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX,
  _LSP6KEY_ADDRESSPERMISSIONS_DAOPERMISSIONS_PREFIX,
  _PERMISSION_VOTE,
  _PERMISSION_PROPOSE,
  _PERMISSION_EXECUTE,
  _PERMISSION_SENDDELEGATE,
  _PERMISSION_RECIEVEDELEGATE,
  _PERMISSION_MASTER,
  
  _KEY_MAJORITY,
  _KEY_PARTICIPATIONRATE,
  _KEY_MINIMUMVOTINGDELAY,
  _KEY_MINIMUMVOTINGPERIOD,

  _KEY_DELEGATEVOTE,
  _KEY_ADDRESSDELEGATES_ARRAY_PREFIX,
  _KEY_ADDRESSDELEGATES_ARRAY_INDEX_PREFIX,

  _KEY_PROPOSAL_PREFIX,
  _KEY_PROPOSAL_JSON_SUFFIX,
  _KEY_PROPOSAL_VOTINGDELAY_SUFFIX,
  _KEY_PROPOSAL_VOTINGPERIOD_SUFFIX,
  _KEY_PROPOSAL_CREATIONTIMESTAMP_SUFFIX,
  _KEY_PROPOSAL_TARGETSARRAY_SUFFIX,
  _KEY_PROPOSAL_DATASARRAY_SUFFIX,
  _KEY_PROPOSAL_PROPOSALCHOICES_SUFFIX,
  _KEY_PROPOSAL_MAXIMUMCHOICESPERVOTE_SUFFIX,
  _KEY_PARTICIPANT_VOTE,

  setDataSingleSelector,
  setDataMultipleSelector,

  _SPLIT_BYTES32_IN_TWO_HALFS
} from "./DaoConstants.sol";
import {ErrorWithNumber} from "../Errors.sol";

/**
 *
* @notice This smart contract is responsible for managing the DAO Keys.
 *
 * @author B00ste
 * @title DaoKeyManager
 * @custom:version 1.1
 */
contract DaoKeyManager is IDaoKeyManager {

  /**
   * @notice Address of the DAO_ACCOUNT.
   */
  address payable private UNIVERSAL_PROFILE;

  /**
   * @notice Address of the KEY_MANAGER.
   */
  address private KEY_MANAGER;

  /**
   * @dev
   */
  constructor(
    address payable _UNIVERSAL_PROFILE,
    address _KEY_MANAGER
  ) {
    UNIVERSAL_PROFILE = _UNIVERSAL_PROFILE;
    KEY_MANAGER = _KEY_MANAGER;
  }


  // --- General Methods.


  /**
   * @inheritdoc IDaoKeyManager
   */
  function togglePermissions(address _to, bytes32[] memory _permissions) external override {
    _verifyPermission(msg.sender, _PERMISSION_MASTER, "MASTER");

    bytes32 permissions = _getPermissions(_to);
    for (uint8 i = 0; i < _permissions.length; i++) {
      if (permissions & _permissions[i] != 0) {
        permissions = bytes32(uint256(permissions) - uint256(_permissions[i]));
      }
      else {
        permissions = bytes32(uint256(permissions) + uint256(_permissions[i]));
      }
    }

    bytes32[] memory keys = new bytes32[](1);
    keys[0] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_DAOPERMISSIONS_PREFIX, bytes20(_to)));
    bytes[] memory values = new bytes[](1);
    values[0] = bytes.concat(permissions);
    _setData(keys, values);
  }

  /**
   * @inheritdoc IDaoKeyManager
   */
  // ToDo remove delegate.
  function delegate(address delegatee) external override {
    _verifyPermission(msg.sender, _PERMISSION_SENDDELEGATE, "SENDDELEGATE");
    _verifyPermission(delegatee, _PERMISSION_RECIEVEDELEGATE, "RECIEVEDELEGATE");

    bytes32 arrayKey = bytes32(bytes.concat(_KEY_ADDRESSDELEGATES_ARRAY_PREFIX, bytes20(delegatee)));
    uint128 arrayLength = uint128(bytes16(IERC725Y(UNIVERSAL_PROFILE).getData(arrayKey)));

    bytes32[] memory keys = new bytes32[](2);
    keys[0] = bytes32(bytes.concat(_SPLIT_BYTES32_IN_TWO_HALFS(arrayKey)[0], bytes16(arrayLength)));
    keys[1] = arrayKey;
    keys[2] = bytes32(bytes.concat(_KEY_DELEGATEVOTE, bytes20(msg.sender)));
    bytes[] memory values = new bytes[](2);
    values[0] = bytes.concat(bytes20(msg.sender));
    values[1] = bytes.concat(bytes16(arrayLength + 1));
    values[2] = bytes.concat(bytes20(delegatee));
  
    _setData(keys, values);
  }

  /**
   * @inheritdoc IDaoKeyManager
   */
  function createProposal(
    string memory title,
    string memory metadataLink,
    uint48 votingDelay,
    uint48 votingPeriod,
    address[] memory targets,
    bytes[] memory datas,
    uint8 choices,
    uint8 choicesPerVote
  ) external override {
    _verifyPermission(msg.sender, _PERMISSION_PROPOSE, "PROPOSE");
    if (targets.length != datas.length) revert ErrorWithNumber(0x0001);
    if (choices > 16) revert ErrorWithNumber(0x0002);
    if (choicesPerVote > choices) revert ErrorWithNumber(0x0003);
    if (votingDelay < uint48(bytes6(IERC725Y(UNIVERSAL_PROFILE).getData(_KEY_MINIMUMVOTINGDELAY)))) revert ErrorWithNumber(0x0004);
    if (votingPeriod < uint48(bytes6(IERC725Y(UNIVERSAL_PROFILE).getData(_KEY_MINIMUMVOTINGPERIOD)))) revert ErrorWithNumber(0x0005);

    uint256 arraysLength = 2 * targets.length;
    bytes10 KEY_PROPOSAL_PREFIX = _KEY_PROPOSAL_PREFIX(uint48(block.timestamp), title);
    bytes32[] memory keys = new bytes32[](arraysLength + 8);
    bytes[] memory values = new bytes[](arraysLength + 8);

    if(arraysLength > 0){
      for (uint16 i = 0; i < targets.length; i++) {
        keys[i] = bytes32(bytes.concat(
          _SPLIT_BYTES32_IN_TWO_HALFS(bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_TARGETSARRAY_SUFFIX)))[0],
          bytes16(uint128(i))
        ));
        keys[i + targets.length] = bytes32(bytes.concat(
          _SPLIT_BYTES32_IN_TWO_HALFS(bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_DATASARRAY_SUFFIX)))[0],
          bytes16(uint128(i))
        ));

        values[i] = bytes.concat(bytes20(targets[i]));
        values[i + targets.length] = datas[i];
      } 
    }

    keys[arraysLength + 0] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_TARGETSARRAY_SUFFIX));
    keys[arraysLength + 1] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_DATASARRAY_SUFFIX));
    keys[arraysLength + 2] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_JSON_SUFFIX));
    keys[arraysLength + 3] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_VOTINGDELAY_SUFFIX));
    keys[arraysLength + 4] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_VOTINGPERIOD_SUFFIX));
    keys[arraysLength + 5] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_CREATIONTIMESTAMP_SUFFIX));
    keys[arraysLength + 6] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_PROPOSALCHOICES_SUFFIX));
    keys[arraysLength + 7] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_MAXIMUMCHOICESPERVOTE_SUFFIX));

    values[arraysLength + 0] = bytes.concat(bytes32(targets.length));
    values[arraysLength + 1] = bytes.concat(bytes32(datas.length));
    values[arraysLength + 2] = bytes(metadataLink);
    values[arraysLength + 3] = bytes.concat(bytes6(uint48(votingDelay)));
    values[arraysLength + 4] = bytes.concat(bytes6(uint48(votingPeriod)));
    values[arraysLength + 5] = bytes.concat(bytes6(uint48(block.timestamp)));
    values[arraysLength + 6] = bytes.concat(bytes1(choices));
    values[arraysLength + 7] = bytes.concat(bytes1(choicesPerVote));

    _setData(keys, values);
  }

  /**
   * @inheritdoc IDaoKeyManager
   */
  function executeProposal(
    bytes10 proposalSignature
  )
    external override
    returns(bool[] memory success, bytes[] memory results)
  {
    _verifyPermission(msg.sender, _PERMISSION_EXECUTE, "EXECUTE");
    if (
      uint256(uint48(bytes6(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(proposalSignature, _KEY_PROPOSAL_CREATIONTIMESTAMP_SUFFIX))))))
      + uint256(uint48(bytes6(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(proposalSignature, _KEY_PROPOSAL_VOTINGDELAY_SUFFIX))))))
      + uint256(uint48(bytes6(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(proposalSignature, _KEY_PROPOSAL_VOTINGPERIOD_SUFFIX))))))
      > block.timestamp
    ) revert ErrorWithNumber(0x0006);
    if (
      uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(
        bytes32(bytes.concat(proposalSignature, _KEY_PROPOSAL_MAXIMUMCHOICESPERVOTE_SUFFIX))
      ))) == 0
    ) revert ErrorWithNumber(0x0007);

    /**
     * @dev Count all the votes by accessing the choices of all of the participants
     * of the DAO.
     * 1. Get the user address and verify its permissions.
     * 2. If `user` has vote permission or send delegate permission
     * we will save his number of votes as 1 and save his choices.
     */  
    uint8 nrOfChoices =  uint8(bytes1(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(proposalSignature, _KEY_PROPOSAL_PROPOSALCHOICES_SUFFIX)))));
    uint256 totalUsers = uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY)));
    uint256[] memory votesByChoiceIndex = new uint256[](nrOfChoices);
    for (uint128 i = 0; i < totalUsers; i++) {
      address user = address(bytes20(IERC725Y(UNIVERSAL_PROFILE).getData(
        bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(i)))
      )));
      bytes32 permissions = _getPermissions(user);
      if (permissions & _PERMISSION_VOTE != 0 || permissions & _PERMISSION_SENDDELEGATE != 0) {
        bytes2 choices = bytes2(IERC725Y(UNIVERSAL_PROFILE).getData(
          _KEY_PARTICIPANT_VOTE(proposalSignature, user)
        ));
        uint256 votes = 1;

        for(uint8 j = 0; j < nrOfChoices; j++) {
          choices & bytes2(uint16(1 << j)) != 0 ? votesByChoiceIndex[j] += votes : 0;
        }
      }
    }

    /**
     * @dev We split all the choices between `negativeVotes` and `positiveVotes`
     *  ____________________________________
     * |  1  |  2  |  3  | 4 | 5  | 6  | 7  |
     * | -42 | -28 | -14 | 0 | 14 | 28 | 42 |
     * |_____|_____|_____|___|____|____|____|
     *
     */
    uint256 totalVotes;
    uint256 negativeVotes;
    uint256 positiveVotes;
    for (uint256 i = 0; i < nrOfChoices; i++) {
      totalVotes += votesByChoiceIndex[i];
      if (i < nrOfChoices/2) {
        negativeVotes += ((nrOfChoices/2 - i) * 100/nrOfChoices) * votesByChoiceIndex[i];
      }
      else {
        positiveVotes += ((i - nrOfChoices/2) * 100/nrOfChoices) * votesByChoiceIndex[i];
      }
    }

    uint256 majority = uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(_KEY_MAJORITY)));
    uint256 participationRate = uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(
      _KEY_PARTICIPATIONRATE
    )));

    /**
     * @dev Check if the proposal has passed and execute the saved methods.
     */
    if(
      totalVotes/totalUsers > participationRate/totalUsers &&
      positiveVotes/totalVotes > majority/totalVotes
    ) {
      bytes32 targetsKey = bytes32(bytes.concat(proposalSignature, _KEY_PROPOSAL_TARGETSARRAY_SUFFIX));
      bytes32 datasKey = bytes32(bytes.concat(proposalSignature, _KEY_PROPOSAL_DATASARRAY_SUFFIX));
      uint256 arrayLength = uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(targetsKey)));
      success = new bool[](arrayLength);
      results = new bytes[](arrayLength);
      for (uint256 i = 0; i < arrayLength; i++) {
        (success[i], results[i]) = address(bytes20(IERC725Y(UNIVERSAL_PROFILE).getData(targetsKey)))
        .call(IERC725Y(UNIVERSAL_PROFILE).getData(datasKey));
      }
    }

  }

  /**
   * @inheritdoc IDaoKeyManager
   */
  function vote(
    bytes10 proposalSignature,
    uint256[] memory choicesArray
  ) external override {
    _verifyPermission(msg.sender, _PERMISSION_VOTE, "VOTE");
    if (
      uint256(bytes32(
        IERC725Y(UNIVERSAL_PROFILE).getData(
          _KEY_PARTICIPANT_VOTE(proposalSignature, msg.sender)
        )
      )) != 0
    ) revert ErrorWithNumber(0x0008);
    if (
      uint8(bytes1(IERC725Y(UNIVERSAL_PROFILE).getData(
        bytes32(bytes.concat(proposalSignature, _KEY_PROPOSAL_MAXIMUMCHOICESPERVOTE_SUFFIX))
      ))) < choicesArray.length
    ) revert ErrorWithNumber(0x0009);

    // Create a BitArray of the voters choices.
    uint256 choices = 0;
    for(uint128 i = 0; i < choicesArray.length; i++) {
      choices = choices + (1 << i);
    }

    // Initialize the keys and values array.
    bytes32[] memory keys;
    bytes[] memory values;

    /**
     * @dev Set the `_KEY_PARTICIPANT_VOTE` for the voter and his delegators if the voter has
     * `_PERMISSION_RECIEVEDELEGATE` with the choices BitArray of the voter.
     */
    if (_getPermissions(msg.sender) & _PERMISSION_RECIEVEDELEGATE != 0) {
      uint256 delegates = uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(
        _KEY_ADDRESSDELEGATES_ARRAY_PREFIX, bytes20(msg.sender)
      )))));

      keys = new bytes32[](delegates + 1);
      values = new bytes[](delegates + 1);
      uint256 arrayLength = 0;

      /**
       * @dev Get each delegator address and save the choices to that address
       * only if it doesn't have other choices already saved.
       */
      for (uint128 i = 0; i < delegates; i++){
        address delegator = address(bytes20(IERC725Y(UNIVERSAL_PROFILE).getData(
          bytes32(bytes.concat(
            _KEY_ADDRESSDELEGATES_ARRAY_INDEX_PREFIX(msg.sender), bytes16(i)
          ))
        )));

        if (
          uint256(bytes32(
            IERC725Y(UNIVERSAL_PROFILE).getData(
              _KEY_PARTICIPANT_VOTE(proposalSignature, msg.sender)
            )
          )) == 0
        ) {
          keys[arrayLength++] = _KEY_PARTICIPANT_VOTE(proposalSignature, delegator);
          values[arrayLength++] = bytes.concat(bytes32(choices));
        }


      }

      keys[arrayLength] = _KEY_PARTICIPANT_VOTE(proposalSignature, msg.sender);
      values[arrayLength] = bytes.concat(bytes32(choices));
    }
    else {
      keys = new bytes32[](1);
      values = new bytes[](1);

      keys[0] = _KEY_PARTICIPANT_VOTE(proposalSignature, msg.sender);
      values[0] = bytes.concat(bytes32(choices));
    }
    _setData(keys, values);
  }


  // --- Internal Methods.


  /**
   * @dev Get the BitArray permissions of an address.
   */
  function _getPermissions(
    address _from
  )
    internal
    view
    returns(bytes32 permissions)
  {
    permissions = bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(
      _LSP6KEY_ADDRESSPERMISSIONS_DAOPERMISSIONS_PREFIX,
      bytes20(_from)
    ))));
  }

  /**
   * @dev Verify if an address has certain permission and revert if not.
   */
  function _verifyPermission(
    address _from,
    bytes32 _permission,
    string memory _permissionName
  )
    internal
    view
  {
    bytes32 permissions = _getPermissions(_from);
    if(permissions & _permission == 0) revert NotAuthorised(_from, _permissionName);
  }

  /**
   * @dev Set the data to the Universal Profile.
   */
  function _setData(
    bytes32[] memory _keys,
    bytes[] memory _values
  ) internal returns(bytes memory result) {
    require(_keys.length == _values.length);
    require(_keys.length > 0);
    
    if(_keys.length == 1) {
      result = ILSP6KeyManager(KEY_MANAGER).execute(
        abi.encodeWithSelector(
          setDataSingleSelector, _keys[0], _values[0]
        )
      );
    }
    else {
      result = ILSP6KeyManager(KEY_MANAGER).execute(
        abi.encodeWithSelector(
          setDataMultipleSelector, _keys, _values
        )
      );
    }
  }

}