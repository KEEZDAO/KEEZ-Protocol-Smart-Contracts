// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// Interfaces for interacting with a Universal Profile.

// getData(...)
import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
// setData(...)
import {ILSP6KeyManager} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/ILSP6KeyManager.sol";

// Openzeppelin Utils.
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// LSP6 Constants
import {
  NoPermissionsSet,
  NotAuthorised
} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Errors.sol";
import {
  setDataSingleSelector,
  setDataMultipleSelector
} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Constants.sol";

// Multisig Constants
import {
  _LSP6KEY_ADDRESSPERMISSIONS_MULTISIGPERMISSIONS_PREFIX,

  _PERMISSION_VOTE,
  _PERMISSION_PROPOSE,
  _PERMISSION_ADD_PERMISSION,
  _PERMISSION_REMOVE_PERMISSION,

  _MULTISIG_QUORUM,

  _MULTISIG_PROPOSAL_SIGNATURE,
  _MULTISIG_PROPOSAL_TARGETS_KEY,
  _MULTISIG_PROPOSAL_DATAS_KEY
} from "./MultisigConstants.sol";

// Error event
import {ErrorWithNumber} from "../Errors.sol";

/**
 *
* @notice This smart contract is responsible for managing the Multisig Keys.
 *
 * @author B00ste
 * @title MultisigKeyManager
 * @custom:version 1.1
 */
contract MultisigKeyManager {
  using ECDSA for bytes32;
  using EnumerableSet for EnumerableSet.AddressSet;

  /**
   * @notice Members of the Multisig.
   */
  EnumerableSet.AddressSet private multisigMembers;

  /**
   * @notice Address of the DAO_ACCOUNT.
   */
  address payable private UNIVERSAL_PROFILE;

  /**
   * @notice Address of the KEY_MANAGER.
   */
  address private KEY_MANAGER;

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
  event ProposalCreated(bytes10 proposalSignature);

  /**
   * @notice Add/Remove members permissions.
   */
  function togglePermissions(address _to, bytes32 _permissions) external {

    // TODO verify each permission from `_permissions` in order to remove it individually or add it individually.
    bytes32 permissions = _getPermissions(_to);
    if (permissions & _permissions != 0) {
      _verifyPermission(msg.sender, _PERMISSION_REMOVE_PERMISSION, "REMOVE_PERMISSION");
      permissions = bytes32(uint256(permissions) - uint256(_permissions));
    }
    else {
      _verifyPermission(msg.sender, _PERMISSION_ADD_PERMISSION, "ADD_PERMISSION");
      permissions = bytes32(uint256(permissions) + uint256(_permissions));
    }

    bytes32[] memory keys;
    bytes[] memory values;
    uint256 setDataArraysLength;

    // If the user has no perimissions left we remove him from the `multisigMembers`
    if(permissions == bytes32(0)) {
      multisigMembers.add(_to);
    }
    // If user's new permissions are equal to the total permissions then it's a new user and we have to add him to `multisigMembers`
    else if(permissions == _permissions) {
      multisigMembers.remove(_to);
    }

    // Save user's permissions.
    keys[setDataArraysLength - 1] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_MULTISIGPERMISSIONS_PREFIX, bytes20(_to)));
    values[setDataArraysLength - 1] = bytes.concat(permissions);
    
    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataMultipleSelector,
        keys, values
      )
    );
  }

  /**
   * @notice Propose to execute methods on behalf of the multisig.
   */
  function proposeExecution(
    address[] memory _targets,
    bytes[] memory _datas
  )
    external
  {
    if(_targets.length != _datas.length) revert ErrorWithNumber(0x0001);
    _verifyPermission(msg.sender, _PERMISSION_PROPOSE, "PROPOSE");

    bytes10 proposalSignature = _MULTISIG_PROPOSAL_SIGNATURE(uint48(block.timestamp));

    uint128 totalLength = uint128(_targets.length * 2);
    bytes32[] memory keys = new bytes32[](totalLength + 2);
    bytes[] memory values = new bytes[](totalLength + 2);

    for (uint128 i = 0; i < _targets.length ; i++) {
      keys[i] = bytes32(bytes.concat(
        bytes16(_MULTISIG_PROPOSAL_TARGETS_KEY(proposalSignature)),
        bytes16(i)
      ));
      values[i] = bytes.concat(bytes20(_targets[i]));

      keys[i + _targets.length] = bytes32(bytes.concat(
        bytes16(_MULTISIG_PROPOSAL_DATAS_KEY(proposalSignature)),
        bytes16(i)
      ));
      values[i + _targets.length] = _datas[i];
    }
    keys[_targets.length * 2 + 0] = _MULTISIG_PROPOSAL_TARGETS_KEY(proposalSignature);
    values[_targets.length * 2 + 0] = bytes.concat(bytes32(_targets.length));
    keys[_targets.length * 2 + 1] = _MULTISIG_PROPOSAL_DATAS_KEY(proposalSignature);
    values[_targets.length * 2 + 1] = bytes.concat(bytes32(_datas.length));

    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataMultipleSelector,
        keys, values
      )
    );

    emit ProposalCreated(proposalSignature);
  }

  /**
   * @notice Create a unique hash for every proposal which should be hashed. 
   */
  function getProposalHash(
    address _signer,
    bytes10 _proposalSignature,
    bool _response
  ) public pure returns(bytes32 _hash) {
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
    bytes10 _proposalSignature,
    bytes[] memory _signatures,
    address[] memory _signers
  )
    external
  {

    uint256 votingMembers;
    for (uint256 i = 0; i < multisigMembers.length(); i++) {
      if (_getPermissions(multisigMembers.at(i)) & _PERMISSION_VOTE != 0) votingMembers++;
    }

    uint256 positiveResponses;
    for(uint256 i = 0; i < _signatures.length; i++) {
      bytes32 _hash = getProposalHash(_signers[i], _proposalSignature, true);
      address recoveredAddress = _hash.recover(_signatures[i]);

      if(multisigMembers.contains(recoveredAddress)) {
        positiveResponses++;
      }
    }

    uint8 quorum = uint8(bytes1(IERC725Y(UNIVERSAL_PROFILE).getData(_MULTISIG_QUORUM)));
    uint256 executables = uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(_MULTISIG_PROPOSAL_TARGETS_KEY(_proposalSignature))));

    if(positiveResponses/votingMembers > quorum/votingMembers) {

      bytes32[] memory keys = new bytes32[](executables * 2);
      bytes[] memory values = new bytes[](executables * 2);
      
      for(uint256 i = 0; i < executables; i++) {
        keys[i] = bytes32(bytes.concat(
          bytes16(_MULTISIG_PROPOSAL_TARGETS_KEY(_proposalSignature)),
          bytes16(uint128(i))
        ));
        values[i] = bytes.concat(bytes32(0));

        keys[executables + i] = bytes32(bytes.concat(
          bytes16(_MULTISIG_PROPOSAL_DATAS_KEY(_proposalSignature)),
          bytes16(uint128(i))
        ));
        values[executables + i] = bytes.concat(bytes32(0));

        ILSP6KeyManager(KEY_MANAGER).execute(
          abi.encodeWithSignature(
            "execute(uint256,address,uint256,bytes)",
            1,
            IERC725Y(UNIVERSAL_PROFILE).getData(keys[i]),
            0,
            IERC725Y(UNIVERSAL_PROFILE).getData(keys[executables + i])
          )
        );
      }

      ILSP6KeyManager(KEY_MANAGER).execute(
        abi.encodeWithSelector(
          setDataMultipleSelector,
          keys, values  
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