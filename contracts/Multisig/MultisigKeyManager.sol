// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import {ILSP6KeyManager} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/ILSP6KeyManager.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {
  NoPermissionsSet,
  NotAuthorised
} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Errors.sol";
import {
  setDataSingleSelector,
  setDataMultipleSelector
} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Constants.sol";
import {
  _LSP6KEY_ADDRESSPERMISSIONS_MULTISIGPERMISSIONS_PREFIX,

  _PERMISSION_VOTE,
  _PERMISSION_PROPOSE,
  _PERMISSION_ADD_MEMBERS,
  _PERMISSION_REMOVE_MEMBERS,

  _MULTISIG_QUORUM,

  _MULTISIG_PARTICIPANTS_KEY,
  _MULTISIG_PARTICIPANTS_KEY_PREFIX,

  _MULTISIG_PROPOSAL_SIGNATURE,
  _MULTISIG_TARGETS_SUFFIX,
  _MULTISIG_PROPOSAL_TARGETS_KEY,
  _MULTISIG_DATAS_SUFFIX,
  _MULTISIG_PROPOSAL_DATAS_KEY
} from "./MultisigConstants.sol";
import {ErrorWithNumber} from "../Errors.sol";

/**
 *
* @notice This smart contract is responsible for managing the Multisig Keys.
 *
 * @author B00ste
 * @title MultisigKeyManager
 * @custom:version
 */
contract MultisigKeyManager {
  using ECDSA for bytes32;

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
    address _KEY_MANAGER,
    uint8 quorum
  ) {
    UNIVERSAL_PROFILE = _UNIVERSAL_PROFILE;
    KEY_MANAGER = _KEY_MANAGER;

    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataSingleSelector,
        _MULTISIG_QUORUM,
        bytes.concat(bytes1(quorum))
      )
    );
  }

  // ToDo Move this to the interface of this contract.
  event ProposalCreated(bytes32 proposalSignature);

  /**
   * @notice Add members to the multisig.
   */
  function addMembers(address[] memory newMembers) external {
    _verifyPermission(msg.sender, _PERMISSION_ADD_MEMBERS, "ADD_MEMBERS");

  }

  /**
   * @notice Remove members from the multisig.
   */
  function addMembers(address[] memory removedMembers) external {
    _verifyPermission(msg.sender, _PERMISSION_REMOVE_MEMBERS, "REMOVE_MEMBERS");

  }

  /**
   * @notice Propose to execute methods on behalf of the multisig.
   */
  function proposeExecution(
    string memory _title,
    address[] memory _targets,
    bytes[] memory _datas
  )
    external
  {
    if(_targets.length != _datas.length) revert ErrorWithNumber(0x0001);
    _verifyPermission(msg.sender, _PERMISSION_PROPOSE, "PROPOSE");

    uint48 currentTimestamp = uint48(block.timestamp);

    uint128 totalLength = uint128(_targets.length * 2);
    bytes32[] memory keys = new bytes32[](totalLength + 2);
    bytes[] memory values = new bytes[](totalLength + 2);

    for (uint128 i = 0; i < _targets.length ; i++) {
      keys[i] = bytes32(bytes.concat(
        bytes16(_MULTISIG_PROPOSAL_TARGETS_KEY(_title, currentTimestamp)),
        bytes16(i)
      ));
      values[i] = bytes.concat(bytes20(_targets[i]));

      keys[i + _targets.length] = bytes32(bytes.concat(
        bytes16(_MULTISIG_PROPOSAL_DATAS_KEY(_title, currentTimestamp)),
        bytes16(i)
      ));
      values[i + _targets.length] = _datas[i];
    }
    keys[0] = _MULTISIG_PROPOSAL_TARGETS_KEY(_title, currentTimestamp);
    values[0] = bytes.concat(bytes32(_targets.length));
    keys[1] = _MULTISIG_PROPOSAL_DATAS_KEY(_title, currentTimestamp);
    values[1] = bytes.concat(bytes32(_datas.length));

    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataMultipleSelector,
        keys, values
      )
    );

    emit ProposalCreated(_MULTISIG_PROPOSAL_SIGNATURE(_title, currentTimestamp));
  }

  /**
   * @notice Create a unique hash for every proposal which should be hashed. 
   */
  function getProposalHash(
    address _signer,
    bytes32 _proposalSignature,
    bool _response
  ) public view returns(bytes32 _hash) {
    _hash = keccak256(abi.encodePacked(
      _signer,
      _proposalSignature,
      _response
    ));
  }

  /**
   * @notice Execute a proposal if you have all the necessary signatures.
   */
  function execute(
    bytes32 _proposalSignature,
    bytes[] memory _signatures,
    address[] memory _signers
  )
    external
  {
    // ToDo verify the result of the signatures.
    if (_signatures.length != _signers.length) revert ErrorWithNumber(0x0010);

    uint256 positiveResponses;
    for(uint256 i = 0; i < _signatures.length; i++) {
      bytes32 _hash = getProposalHash(_signers[i], _proposalSignature, true);
      address recoveredAddress = _hash.recover(_signatures[i]);

      if(recoveredAddress == _signers[i]) {
        positiveResponses++;
      }
    }

    // ToDo compaer the positiveNumbers to the quorum needed for execution.
    uint8 quorum = IERC725Y(UNIVERSAL_PROFILE).getData(_MULTISIG_QUORUM);
    uint256 members;
    if(positiveResponses/members > quorum/members) {
      // ToDo fix this to execute the datas of the proposals at targets.
      // ToDo remove the targets and datas from the universal profile data
      ILSP6KeyManager(KEY_MANAGER).execute(
        abi.encodeWithSignature(
          "execute(uint256,address,uint256,bytes)",
          1,
          _tokenAddress,
          0,
          abi.encodeWithSignature(
            "authorizeOperator(address,uint256)",
            address(this),
            _to,
            _amount
          )
        )
      );
    }

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
      _LSP6KEY_ADDRESSPERMISSIONS_MULTISIGPERMISSIONS_PREFIX,
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

}