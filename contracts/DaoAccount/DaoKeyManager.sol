// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import {LSP6KeyManager} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6KeyManager.sol";
import {
  NoPermissionsSet,
  NotAuthorised
} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Errors.sol";
import {
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
  _KEY_PROPOSAL_PROPOSALCHOICESARRAY_SUFFIX,
  _KEY_PROPOSAL_MAXIMUMCHOICESPERVOTE_SUFFIX,
  _KEY_PARTICIPANT_VOTE,

  setDataSingleSelector,
  setDataMultipleSelector,

  _SPLIT_BYTES32_IN_TWO_HALFS
} from "./DaoConstants.sol";

/**
 *
* @notice This smart contract is responsible for managing the DAO Keys.
 *
 * @author B00ste
 * @title DaoKeyManager
 * @custom:version 0.92
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
    string memory title,
    string memory description,
    address[] memory targets,
    bytes[] memory datas,
    bytes32[] memory choices,
    uint8 maximumChoicesPerVote
  ) external {
    _verifyPermission(msg.sender, _PERMISSION_PROPOSE, "PROPOSE");
    require(
      targets.length == datas.length,
      "targets.length must be equal to datas.length"
    );
    require(
      choices.length <= 16 &&
      maximumChoicesPerVote <= 16,
      "You can have maximum 16 choices."
    );

    bytes10 KEY_PROPOSAL_PREFIX = _KEY_PROPOSAL_PREFIX(uint48(block.timestamp), title);
    bytes32[] memory keys = new bytes32[](targets.length + datas.length + choices.length + 4);
    bytes[] memory values = new bytes[](targets.length + datas.length + choices.length + 4);

    uint256 maxLength = targets.length > choices.length ? targets.length : choices.length ;
    for (uint16 i = 0; i < maxLength; i++) {
      if (i < targets.length) {
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
      if (i < choices.length) {
        keys[i + (2 * targets.length)] = bytes32(bytes.concat(
          _SPLIT_BYTES32_IN_TWO_HALFS(bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_PROPOSALCHOICESARRAY_SUFFIX)))[0],
          bytes16(uint128(i))
        ));

        values[i + (2 * targets.length)] = bytes.concat(choices[i]);
      }
    }
    keys[0] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_TITLE_SUFFIX));
    keys[0] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_DESCRIPTION_SUFFIX));
    keys[0] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_CREATIONTIMESTAMP_SUFFIX));
    keys[0] = bytes32(bytes.concat(KEY_PROPOSAL_PREFIX, _KEY_PROPOSAL_MAXIMUMCHOICESPERVOTE_SUFFIX));

    values[0] = bytes(title);
    values[0] = bytes(description);
    values[0] = bytes.concat(bytes6(uint48(block.timestamp)));
    values[0] = bytes.concat(bytes1(maximumChoicesPerVote));

    _setData(keys, values);
  }

  /**
   * @notice Execute the calldata of the Proposal if there is one.
   */
  function executeProposal(bytes10 proposalSignature) external {
    _verifyPermission(msg.sender, _PERMISSION_EXECUTE, "EXECUTE");
    require(
      uint256(uint48(bytes6(IERC725Y(UNIVERSAL_PROFILE).getData(_KEY_PROPOSAL_CREATIONTIMESTAMP_SUFFIX))))
      + uint256(uint48(bytes6(IERC725Y(UNIVERSAL_PROFILE).getData(_KEY_VOTINGDELAY))))
      + uint256(uint48(bytes6(IERC725Y(UNIVERSAL_PROFILE).getData(_KEY_VOTINGPERIOD))))
      < block.timestamp,
      "The proposal's time did not expire."
    );
    // ToDo verify if the proposal has passed and execute the datas if necessary.
  }

  /**
   * @notice Vote on a proposal.
   */
  function vote(bytes10 proposalSignature, bytes30 voteDescription, bytes32[] memory choicesArray) external {
    _verifyPermission(msg.sender, _PERMISSION_VOTE, "VOTE");
    require(
      uint256(bytes32(
        IERC725Y(UNIVERSAL_PROFILE).getData(
          _KEY_PARTICIPANT_VOTE(proposalSignature, msg.sender)
        )
      )) == 0,
      "User already voted."
    );
    require(
      uint8(bytes1(IERC725Y(UNIVERSAL_PROFILE).getData(
        bytes32(bytes.concat(proposalSignature, _KEY_PROPOSAL_MAXIMUMCHOICESPERVOTE_SUFFIX))
      ))) >= choicesArray.length,
      "You have more choices than allowed."
    );

    uint16 choices = 0;
    for(uint128 i = 0; i < choicesArray.length; i++) {
      if(
      bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(
        bytes32(bytes.concat(
          _SPLIT_BYTES32_IN_TWO_HALFS(
            bytes32(bytes.concat(
              proposalSignature, _KEY_PROPOSAL_PROPOSALCHOICESARRAY_SUFFIX
            ))
          )[0],
          bytes16(i)
        ))
      )) == choicesArray[i]
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

  function _setData(bytes32[] memory _keys, bytes[] memory _values) internal {
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