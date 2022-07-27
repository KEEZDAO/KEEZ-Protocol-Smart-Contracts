// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import {LSP6KeyManager} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6KeyManager.sol";
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

  _KEY_TITLE,
  _KEY_DESCRIPTION,
  _KEY_MAJORITY,
  _KEY_PARTICIPATIONRATE,
  _KEY_VOTINGDELAY,
  _KEY_VOTINGPERIOD,
  _KEY_TOKENGATED,

  _KEY_DELEGATEVOTE,
  _KEY_ADDRESSDELEGATES_ARRAY_PREFIX,

  _KEY_PROPOSAL_PREFIX,
  _KEY_PROPOSAL_TITLE_SUFFIX,
  _KEY_PROPOSAL_DESCRIPTION_SUFFIX,
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
import {
  ErrorWithNumber
} from "../DaoCreatorErrors.sol";

/**
 *
* @notice This smart contract is responsible for managing the DAO Keys.
 *
 * @author B00ste
 * @title DaoKeyManager
 * @custom:version 1
 */
contract DaoKeyManager {

  /**
   * @notice Address of the DAO_ACCOUNT.
   */
  address payable private UNIVERSAL_PROFILE;

  /**
   * @notice Address of the KEY_MANAGER.
   */
  address private KEY_MANAGER;

  /**
   * @notice Address of the creator.
   */
  address private CREATOR;

  constructor(
    address payable _UNIVERSAL_PROFILE,
    address _KEY_MANAGER
  ) {
    CREATOR = msg.sender;
    UNIVERSAL_PROFILE = _UNIVERSAL_PROFILE;
    KEY_MANAGER = _KEY_MANAGER;
  }
  function initialize(
    string memory title,
    string memory description,
    uint8 majority,
    uint8 participationRate,
    uint48 votingDelay,
    uint48 votingPeriod,
    bytes1 tokenGated
  ) external {
    require(msg.sender == CREATOR);

    bytes32[] memory keys = new bytes32[](7);
    keys[0] = _KEY_TITLE;
    keys[1] = _KEY_DESCRIPTION;
    keys[2] = _KEY_MAJORITY;
    keys[3] = _KEY_PARTICIPATIONRATE;
    keys[4] = _KEY_VOTINGDELAY;
    keys[5] = _KEY_VOTINGPERIOD;
    keys[6] = _KEY_TOKENGATED;

    bytes[] memory values = new bytes[](7);
    values[0] = bytes(title);
    values[1] = bytes(description);
    values[2] = bytes.concat(bytes1(majority));
    values[3] = bytes.concat(bytes1(participationRate));
    values[4] = bytes.concat(bytes6(votingDelay));
    values[5] = bytes.concat(bytes6(votingPeriod));
    values[6] = bytes.concat(tokenGated);

    _setData(keys, values);
  }


  // --- General Methods.


  /**
   * @notice Toggle permissions of an address.
   */
  function togglePermissions(address _to, bytes32[] memory _permissions) external {
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
   * @notice Delegate your vote.
   */
  function delegate(address delegatee) external {
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
  
    IERC725Y(UNIVERSAL_PROFILE).setData(keys, values);
  }

  /**
   * @notice Create a proposal.
   */
  function createProposal(
    bytes32 title,
    string memory description,
    address[] memory targets,
    bytes[] memory datas,
    uint8 choices,
    uint8 choicesPerVote
  ) external {
    _verifyPermission(msg.sender, _PERMISSION_PROPOSE, "PROPOSE");
    if (targets.length != datas.length) revert ErrorWithNumber(0x000C);
    if (choices > 16) revert ErrorWithNumber(0x000D);
    if (choicesPerVote > choices) revert ErrorWithNumber(0x000E);

    uint256 arraysLength = 2 * targets.length;
    bytes10 KEY_PROPOSAL_PREFIX = _KEY_PROPOSAL_PREFIX(uint48(block.timestamp), title);
    bytes32[] memory keys = new bytes32[](arraysLength + 7);
    bytes[] memory values = new bytes[](arraysLength + 7);

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
    keys[arraysLength + 2] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_TITLE_SUFFIX));
    keys[arraysLength + 3] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_DESCRIPTION_SUFFIX));
    keys[arraysLength + 4] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_CREATIONTIMESTAMP_SUFFIX));
    keys[arraysLength + 5] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_PROPOSALCHOICES_SUFFIX));
    keys[arraysLength + 6] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_MAXIMUMCHOICESPERVOTE_SUFFIX));

    values[arraysLength + 0] = bytes.concat(bytes32(targets.length));
    values[arraysLength + 1] = bytes.concat(bytes32(datas.length));
    values[arraysLength + 2] = bytes.concat(title);
    values[arraysLength + 3] = bytes(description);
    values[arraysLength + 4] = bytes.concat(bytes6(uint48(block.timestamp)));
    values[arraysLength + 5] = bytes.concat(bytes1(choices));
    values[arraysLength + 6] = bytes.concat(bytes1(choicesPerVote));

    _setData(keys, values);
  }

  /**
   * @notice Execute the calldata of the Proposal if there is one.
   */
  function executeProposal(
    bytes10 proposalSignature
  )
    external
    returns(bool success, bytes memory res)
  {
    _verifyPermission(msg.sender, _PERMISSION_EXECUTE, "EXECUTE");
    if (
      uint256(uint48(bytes6(IERC725Y(UNIVERSAL_PROFILE).getData(_KEY_PROPOSAL_CREATIONTIMESTAMP_SUFFIX))))
      + uint256(uint48(bytes6(IERC725Y(UNIVERSAL_PROFILE).getData(_KEY_VOTINGDELAY))))
      + uint256(uint48(bytes6(IERC725Y(UNIVERSAL_PROFILE).getData(_KEY_VOTINGPERIOD))))
      > block.timestamp
    ) revert ErrorWithNumber(0x000F);
    if (
      uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(
        bytes32(bytes.concat(proposalSignature, _KEY_PROPOSAL_MAXIMUMCHOICESPERVOTE_SUFFIX))
      ))) == 0
    ) revert ErrorWithNumber(0x0010);

    /**
     * @dev Count all the votes by accessing the choices of all of the participants
     * of the DAO.
     * 1. Get the user address and verify its permissions.
     * 2. If `user` has vote permission and did not delegate his vote
     * we will save his number of votes as 1 and save his choices for later use.
     * 3. We verify if the `user` has the RECIEVEDELEGATE permission and if so
     * we will increase his number of votes by the number of votes delegated to him.
     * 4. After we got all the needed info we can add the number of votes to the choises of the `user`
     */  
    uint8 nrOfChoices =  uint8(bytes1(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(proposalSignature, _KEY_PROPOSAL_PROPOSALCHOICES_SUFFIX)))));
    uint256 totalUsers = uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY)));
    uint256[] memory votesByChoiceIndex = new uint256[](nrOfChoices);
    for (uint128 i = 0; i < totalUsers; i++) {
      address user = address(bytes20(IERC725Y(UNIVERSAL_PROFILE).getData(
        bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(i)))
      )));
      bytes32 permissions = _getPermissions(user);
      bytes20 delegatedTo = bytes20(IERC725Y(UNIVERSAL_PROFILE).getData(
        bytes32(bytes.concat(_KEY_DELEGATEVOTE, bytes20(user)))
      ));
      if (permissions & _PERMISSION_VOTE != 0) {
        bytes2 choices;
        uint256 votes;
        if (delegatedTo == bytes20(0)) {
          votes = 1;
          choices = bytes2(IERC725Y(UNIVERSAL_PROFILE).getData(
            _KEY_PARTICIPANT_VOTE(proposalSignature, user)
          ));
        }
        else {
          votes = 0;
        }
        if (permissions & _PERMISSION_RECIEVEDELEGATE != 0) {
          votes += uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(
            bytes32(bytes.concat(_KEY_ADDRESSDELEGATES_ARRAY_PREFIX, bytes20(user)))
          )));
        }
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
        negativeVotes += ((nrOfChoices/2 - i) * 100/nrOfChoices);
      }
      else {
        positiveVotes += ((i - nrOfChoices/2) * 100/nrOfChoices);
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
      for (uint256 i = 0; i < arrayLength; i++) {
        (success, res) = address(bytes20(IERC725Y(UNIVERSAL_PROFILE).getData(targetsKey)))
        .call(IERC725Y(UNIVERSAL_PROFILE).getData(datasKey));
      }
    }

  }

  /**
   * @notice Vote on a proposal.
   */
  function vote(
    bytes10 proposalSignature,
    bytes30 voteDescription,
    uint8[] memory choicesArray
  ) external {
    _verifyPermission(msg.sender, _PERMISSION_VOTE, "VOTE");
    if (
      uint256(bytes32(
        IERC725Y(UNIVERSAL_PROFILE).getData(
          _KEY_PARTICIPANT_VOTE(proposalSignature, msg.sender)
        )
      )) != 0
    ) revert ErrorWithNumber(0x0011);
    if (
      uint8(bytes1(IERC725Y(UNIVERSAL_PROFILE).getData(
        bytes32(bytes.concat(proposalSignature, _KEY_PROPOSAL_MAXIMUMCHOICESPERVOTE_SUFFIX))
      ))) < choicesArray.length
    ) revert ErrorWithNumber(0x0012);

    uint16 choices = 0;
    for(uint128 i = 0; i < choicesArray.length; i++) {
      if(
      uint8(bytes1(IERC725Y(UNIVERSAL_PROFILE).getData(
        bytes32(bytes.concat(
          _SPLIT_BYTES32_IN_TWO_HALFS(
            bytes32(bytes.concat(
              proposalSignature, _KEY_PROPOSAL_PROPOSALCHOICES_SUFFIX
            ))
          )[0],
          bytes16(i)
        ))
      ))) == choicesArray[i]
      ) {
        choices = choices + uint16(1 << i);
      }
    }

    bytes32[] memory keys = new bytes32[](1);
    keys[0] = _KEY_PARTICIPANT_VOTE(proposalSignature, msg.sender);
    bytes[] memory values = new bytes[](1);
    values[0] = bytes.concat(voteDescription, bytes2(choices));
    _setData(keys, values);
  }


  // --- Internal Methods.


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

  function _setData(
    bytes32[] memory _keys,
    bytes[] memory _values
  ) internal {
    require(_keys.length == _values.length);
    require(_keys.length > 0);
    if(_keys.length == 1) {
      LSP6KeyManager(KEY_MANAGER).execute(abi.encodeWithSelector(
        setDataSingleSelector, _keys[0], _values[0]
      ));
    }
    else {
      LSP6KeyManager(KEY_MANAGER).execute(abi.encodeWithSelector(
        setDataMultipleSelector, _keys, _values
      ));
    }
  }

}