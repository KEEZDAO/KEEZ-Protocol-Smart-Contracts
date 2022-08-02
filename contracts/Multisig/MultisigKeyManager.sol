// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// Interfaces for interacting with a Universal Profile.

// getData(...)
import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
// setData(...)
import {ILSP6KeyManager} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/ILSP6KeyManager.sol";

// Openzeppelin Utils.
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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

  _MULTISIG_PARTICIPANTS_KEY,

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
 * @custom:version 1.2
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
        _MULTISIG_QUORUM, bytes.concat(bytes1(quorum))
      )
    );
  }

  // ToDo Move this to the interface of this contract.
  event ProposalCreated(bytes10 proposalSignature);

  /**
   * @notice Create a `_hash` for signing and that signature can be used
   * by the user `_to` to redeem the permissions.
   */
  function newPermissionMessage(
    address _to,
    bytes32 _permissions
  ) public pure returns(bytes32 _hash) {
    _hash = keccak256(abi.encode(
      _to, _permissions
    ));
  }

  /**
   * @notice User can claim a `_permission` if he recieved the `_signature`
   * from someone with the ADD_PERMISSION permission, otherwise it will revert.
   */
  function claimPermission(bytes32 _permissions, bytes memory _signature) external {
    bytes32 _hash = newPermissionMessage(msg.sender, _permissions);
    address recoveredAddress = _hash.recover(_signature);
    _verifyPermission(recoveredAddress, _PERMISSION_ADD_PERMISSION, "ADD_PERMISSION");
    _addPermissions(msg.sender, _permissions);
  }

  /**
   * @notice 
   */
  function addPermissions(address _to, bytes32 _permissions) external {
    _verifyPermission(msg.sender, _PERMISSION_ADD_PERMISSION, "ADD_PERMISSION");
    _addPermissions(_to, _permissions);
  }

  /**
   * @notice 
   */
  function removePermissions(address _to, bytes32 _permissions) external {
    _verifyPermission(msg.sender, _PERMISSION_REMOVE_PERMISSION, "REMOVE_PERMISSION");
    _removePermissions(_to, _permissions);
  }

  /**
   * @dev Add `_permissions` to an address `_to`.
   */
  function _addPermissions(address _to, bytes32 _permissions) internal {
    // Check if user has any permisssions. If not add him to the list of participants.
    bytes32 currentPermissions = _getPermissions(_to);
    if (currentPermissions == bytes32(0))
    _arrayAdd(_MULTISIG_PARTICIPANTS_KEY, bytes.concat(bytes20(_to)));
    // Update the permissions in a local variable.
    for(uint256 i = 0; i < 4; i++) {
      if (currentPermissions & bytes32(1 << i) == 0 && _permissions & bytes32(1 << i) != 0)
      currentPermissions = bytes32(uint256(currentPermissions) + (1 << i));
    }
    // Set the local permissions to the Universal Profile.
    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataSingleSelector,
        bytes32(bytes.concat(
          _LSP6KEY_ADDRESSPERMISSIONS_MULTISIGPERMISSIONS_PREFIX,
          bytes20(_to)
        )),
        bytes.concat(currentPermissions)
      )
    );
  }

  /**
   * @dev Remove `_permissions` from an address `_to`.
   */
  function _removePermissions(address _to, bytes32 _permissions) internal {
    // Update the permissions in a local variable.
    bytes32 currentPermissions = _getPermissions(_to);
    for(uint256 i = 0; i < 4; i++) {
      if (currentPermissions & bytes32(1 << i) != 0 && _permissions & bytes32(1 << i) != 0)
      currentPermissions = bytes32(uint256(currentPermissions) - (1 << i));
    }
    // Check if user has any permissions left. If not, remove him from the list of participants.
    if (currentPermissions == bytes32(0))
    _arrayRemove(_MULTISIG_PARTICIPANTS_KEY, bytes.concat(bytes20(_to)));
    // Set the local permissions to the Universal Profile.
    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataSingleSelector,
        bytes32(bytes.concat(
          _LSP6KEY_ADDRESSPERMISSIONS_MULTISIGPERMISSIONS_PREFIX,
          bytes20(_to)
        )),
        bytes.concat(currentPermissions)
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

    uint256 votingMembers = uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(_MULTISIG_PARTICIPANTS_KEY)));
    uint256 positiveResponses;
    for(uint256 i = 0; i < _signatures.length; i++) {
      bytes32 _hash = getProposalHash(_signers[i], _proposalSignature, true);
      address recoveredAddress = _hash.recover(_signatures[i]);

      if(_getPermissions(recoveredAddress) & _PERMISSION_VOTE != 0) {
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

  /**
   * @dev Get the permissions of an address.
   */
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

  /**
   * @dev Verify if an address has a permission.
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
   * @dev Returns `arrayLenth` + 1 if the array at `_key` doesn't contain `_value`
   * and the index of the `_value` inside the array at `_key` if it contains `_value`.
   */
  function _arrayContains(
    bytes32 _key,
    bytes memory _value
  ) internal view returns(uint256 index) {
    uint256 arrayLength = uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(_key)));
    index = arrayLength + 1;
    for (uint128 i = 0; i < arrayLength; i++) {
      bytes memory value = IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(
        bytes16(_key),
        bytes16(i)
      )));

      if (_value.length == value.length) {
        for (uint128 j = 0; value[j] == _value[j]; i++) {
          if (j == _value.length - 1) index = uint256(i);
        }
      }
    }
  }

  /**
   * @dev Add an element to the array at `_key` if it is non-existent yet.
   */
  function _arrayAdd(
    bytes32 _key,
    bytes memory _value
  ) internal returns(bool) {
    uint256 arrayLength = uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(_key)));
    if (_arrayContains(_key,_value) != arrayLength + 1) return false;

    bytes32[] memory keys = new bytes32[](2);
    bytes[] memory values = new bytes[](2);

    keys[0] = _key;
    values[0] = bytes.concat(bytes32(arrayLength + 1));

    keys[1] = bytes32(bytes.concat(
      bytes16(_key),
      bytes16(uint128(arrayLength))
    ));
    values[1] = _value;

    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataMultipleSelector,
        keys, values
      )
    );
    return true;
  }

  /**
   * @dev Remove an array element if it exists in the array at `_key`.
   */
  function _arrayRemove(
    bytes32 _key,
    bytes memory _value
  ) internal returns(bool) {
    uint256 arrayLength = uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(_key)));
    uint256 valueIndex = _arrayContains(_key,_value);
    if (valueIndex == arrayLength + 1) return false;

    bytes32[] memory keys = new bytes32[](arrayLength - valueIndex + 1);
    bytes[] memory values = new bytes[](arrayLength - valueIndex + 1);

    for (uint256 i = valueIndex; i < arrayLength; i++) {
      keys[i] = bytes32(bytes.concat(
        bytes16(_key),
        bytes16(uint128(i))
      ));
      values[i] = bytes.concat(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(
        bytes16(_key),
        bytes16(uint128(i + 1))
      ))));
    }

    keys[arrayLength - valueIndex] = _key;
    values[arrayLength - valueIndex] = bytes.concat(bytes32(arrayLength - 1));

    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataMultipleSelector,
        keys, values
      )
    );
    return true;
  }

}