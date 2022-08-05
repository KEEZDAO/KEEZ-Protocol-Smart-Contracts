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
  _PERMISSION_EXECUTE_PROPOSAL,

  _MULTISIG_QUORUM_KEY,

  _MULTISIG_PARTICIPANTS_ARRAY_KEY,
  _MULTISIG_PARTICIPANTS_ARRAY_PREFIX,
  _MULTISIG_PARTICIPANTS_MAPPING_PREFIX,

  _MULTISIG_PROPOSAL_SIGNATURE,
  _MULTISIG_PROPOSAL_PAYLOADS_KEY
} from "./MultisigConstants.sol";

// Custom error.
import {IndexedError} from "../Errors.sol";

// Library for array interaction
import {ArrayWithMappingLibrary} from "../ArrayWithMappingLibrary.sol";

/**
 *
* @notice This smart contract is responsible for managing the Multisig Keys.
 *
 * @author B00ste
 * @title MultisigKeyManager
 * @custom:version 1.3
 */
contract MultisigKeyManager {
  using ECDSA for bytes32;

  /**
   * @notice Nonce for claiming permissions.
   */
  mapping(address => uint256) claimPermissionNonce;

  /**
   * @notice Nonce for voting.
   */
  mapping(address => uint256) votingNonce;

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
    address _KEY_MANAGER
  ) {
    UNIVERSAL_PROFILE = _UNIVERSAL_PROFILE;
    KEY_MANAGER = _KEY_MANAGER;
  }

  // ToDo Move this to the interface of this contract.
  event ProposalCreated(bytes10 proposalSignature);

  /**
   * @notice Create a `_hash` for signing and that signature can be used
   * by the user `_to` to redeem the permissions.
   */
  function getNewPermissionHash(
    address _to,
    bytes32 _permissions
  ) public view returns(bytes32 _hash) {
    _hash = keccak256(abi.encode(
      _to, _permissions, claimPermissionNonce[_to]
    ));
  }

  /**
   * @notice User can claim a `_permission` if he recieved the `_signature`
   * from someone with the ADD_PERMISSION permission, otherwise it will revert.
   */
  function claimPermission(bytes32 _permissions, bytes memory _signature) external {
    bytes32 _hash = getNewPermissionHash(msg.sender, _permissions);
    address recoveredAddress = _hash.recover(_signature);
    _verifyPermission(recoveredAddress, _PERMISSION_ADD_PERMISSION, "ADD_PERMISSION");
    _addPermissions(msg.sender, _permissions);
    claimPermissionNonce[msg.sender]++;
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
    ArrayWithMappingLibrary._addElement(
      UNIVERSAL_PROFILE,
      KEY_MANAGER,
      _MULTISIG_PARTICIPANTS_ARRAY_KEY,
      _MULTISIG_PARTICIPANTS_ARRAY_PREFIX,
      _MULTISIG_PARTICIPANTS_MAPPING_PREFIX,
      bytes.concat(bytes20(_to))
    );
    // Update the permissions in a local variable.
    for(uint256 i = 0; i < 5; i++) {
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
    for(uint256 i = 0; i < 5; i++) {
      if (currentPermissions & bytes32(1 << i) != 0 && _permissions & bytes32(1 << i) != 0)
      currentPermissions = bytes32(uint256(currentPermissions) - (1 << i));
    }
    bytes memory encodedCurrentPermissions = bytes.concat(currentPermissions);
    // Check if user has any permissions left. If not, remove him from the list of participants.
    if (currentPermissions == bytes32(0)) {
      ArrayWithMappingLibrary._removeElement(
        UNIVERSAL_PROFILE,
        KEY_MANAGER,
        _MULTISIG_PARTICIPANTS_ARRAY_KEY,
        _MULTISIG_PARTICIPANTS_ARRAY_PREFIX,
        _MULTISIG_PARTICIPANTS_MAPPING_PREFIX,
        bytes.concat(bytes20(_to))
      );
      encodedCurrentPermissions = "";
    }
    // Set the local permissions to the Universal Profile.
    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataSingleSelector,
        bytes32(bytes.concat(
          _LSP6KEY_ADDRESSPERMISSIONS_MULTISIGPERMISSIONS_PREFIX,
          bytes20(_to)
        )),
        encodedCurrentPermissions
      )
    );
  }

  /**
   * @notice Propose to execute methods on behalf of the multisig.
   */
  function proposeExecution(
    bytes[] calldata _payloads
  )
    external
  {
    if(_payloads.length == 0) revert IndexedError("Multisig", 0x01);
    _verifyPermission(msg.sender, _PERMISSION_PROPOSE, "PROPOSE");

    bytes10 proposalSignature = _MULTISIG_PROPOSAL_SIGNATURE(uint48(block.timestamp));

    bytes32 key = _MULTISIG_PROPOSAL_PAYLOADS_KEY(proposalSignature);
    bytes memory value = abi.encode(_payloads);

    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataSingleSelector,
        key, value
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
  ) public view returns(bytes32 _hash) {
    _hash = keccak256(abi.encodePacked(
      _signer,
      _proposalSignature,
      _response,
      votingNonce[_signer]
    ));
  }

  /**
   * @notice Execute a proposal if you have all the necessary signatures.
   */
  function execute(
    bytes10 _proposalSignature,
    bytes[] calldata _signatures,
    address[] calldata _signers
  )
    external
  {
    _verifyPermission(msg.sender, _PERMISSION_EXECUTE_PROPOSAL, "EXECUTE_PROPOSAL");

    bytes32[] memory keys = new bytes32[](2);
    keys[0] = _MULTISIG_PARTICIPANTS_ARRAY_KEY;
    keys[1] = _MULTISIG_QUORUM_KEY;
    bytes[] memory encodedResponses = IERC725Y(UNIVERSAL_PROFILE).getData(keys);
    uint256 votingMembers = uint256(bytes32(encodedResponses[0]));
    uint8 quorum = uint8(bytes1(encodedResponses[1]));

    if ((_signatures.length * 100) / votingMembers < quorum) revert IndexedError("Multisig", 0x02);

    // Count the postive responses.
    uint256 positiveResponses;
    for(uint256 i = 0; i < _signatures.length; i++) {
      bytes32 _hash = getProposalHash(_signers[i], _proposalSignature, true);
      address recoveredAddress = _hash.recover(_signatures[i]);

      if(_getPermissions(recoveredAddress) & _PERMISSION_VOTE != 0) {
        positiveResponses++;

        votingNonce[recoveredAddress]++;
      }
    }

    // Verify if there are enough pro signatures and if yes, execute.
    if((positiveResponses * 100) / votingMembers < quorum) { 
      bytes[] memory _payloads = abi.decode(
        IERC725Y(UNIVERSAL_PROFILE).getData(_MULTISIG_PROPOSAL_PAYLOADS_KEY(_proposalSignature)),
        (bytes[])
      );

      for(uint256 i = 0; i < _payloads.length; i++) {
        ILSP6KeyManager(KEY_MANAGER).execute(_payloads[i]);
      }
    }
    else revert IndexedError("Multisig", 0x03);

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

}