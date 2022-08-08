// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// getData(...)
import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
// setData(...), execute(...)
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

// Dao Constants
import {
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY,
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX,
  _LSP6KEY_ADDRESSPERMISSIONS_DAOPERMISSIONS_PREFIX,
  _PERMISSION_VOTE,
  _PERMISSION_PROPOSE,
  _PERMISSION_EXECUTE,
  _PERMISSION_SEND_DELEGATE,
  _PERMISSION_RECIEVE_DELEGATE,
  _PERMISSION_ADD_PERMISSIONS,
  _PERMISSION_REMOVE_PERMISSIONS,

  _DAO_PARTICIPANTS_ARRAY_KEY,
  _DAO_PARTICIPANTS_ARRAY_PREFIX,
  _DAO_PARTICIPANTS_MAPPING_PREFIX,

  _DAO_DELEGATEE_PREFIX,
  _DAO_DELEGATES_ARRAY_PREFIX,
  
  _DAO_MAJORITY_KEY,
  _DAO_PARTICIPATION_RATE_KEY,
  _DAO_MINIMUM_VOTING_DELAY_KEY,
  _DAO_MINIMUM_VOTING_PERIOD_KEY,
  _DAO_MINIMUM_EXECUTION_DELAY_KEY,

  _DAO_PROPOSAL_SIGNATURE,
  _DAO_PROPOSAL_JSON_METADATA_SUFFIX,
  _DAO_PROPOSAL_VOTING_DELAY_SUFFIX,
  _DAO_PROPOSAL_VOTING_PERIOD_SUFFIX,
  _DAO_PROPOSAL_EXECUTION_DELAY_SUFFIX,
  _DAO_PROPOSAL_CREATION_TIMESTAMP_SUFFIX,
  _DAO_PROPOSAL_PAYLOADS_ARRAY_SUFFIX,
  _DAO_PROPOSAL_PROPOSAL_CHOICES_SUFFIX,
  _DAO_PROPOSAL_MAXIMUM_CHOICES_PER_VOTE_SUFFIX
} from "./DaoConstants.sol";

// Custom error
import {IndexedError} from "../Errors.sol";

// Contract's interface
import {IDaoProposals} from "./IDaoProposals.sol";

/**
 *
* @notice This smart contract is responsible for managing the DAO Proposals Keys.
 *
 * @author B00ste
 * @title DaoProposals
 * @custom:version 1.4
 */
contract DaoProposals is IDaoProposals {
  using ECDSA for bytes32;

  /**
   * @dev Nonce for voting.
   */
  mapping(address => uint256) private votingNonce;

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
   * @inheritdoc IDaoProposals
   */
  function createProposal(
    string calldata _title,
    string calldata _metadataLink,
    bytes32 _votingDelay,
    bytes32 _votingPeriod,
    bytes32 _executionDelay,
    bytes[] calldata _payloads,
    bytes32 _choices,
    bytes32 _choicesPerVote
  )
    external
    override
  {
    _verifyPermission(msg.sender, _PERMISSION_PROPOSE, "PROPOSE");
    if (_choicesPerVote > _choices) revert IndexedError("DaoProposals", 0x01);
    if (_votingDelay < bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(_DAO_MINIMUM_VOTING_DELAY_KEY))) revert IndexedError("DaoProposals", 0x02);
    if (_votingPeriod < bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(_DAO_MINIMUM_VOTING_PERIOD_KEY))) revert IndexedError("DaoProposals", 0x03);
    if (_executionDelay < bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(_DAO_MINIMUM_EXECUTION_DELAY_KEY))) revert IndexedError("DaoProposals", 0x04);

    bytes10 proposalSignature = _DAO_PROPOSAL_SIGNATURE(
      bytes6(keccak256(abi.encode(_title, block.timestamp)))
    );
    bytes32[] memory keys = new bytes32[](7);
    bytes[] memory values = new bytes[](7);

    if(_payloads.length > 0){
      keys[0] = bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_PAYLOADS_ARRAY_SUFFIX));
      values[0] = abi.encode(_payloads);
    }
    // Key and value for the proposal's JSON metadata link
    keys[1] = bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_JSON_METADATA_SUFFIX));
    values[1] = bytes(_metadataLink);
    // Key and value for the proposal voting delay
    keys[2] = bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_VOTING_DELAY_SUFFIX));
    values[2] = bytes.concat(bytes32(_votingDelay));
    // Key an value for the proposal voting period
    keys[3] = bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_VOTING_PERIOD_SUFFIX));
    values[3] = bytes.concat(bytes32(_votingPeriod));
    // Key an value for the proposal execution delay
    keys[3] = bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_EXECUTION_DELAY_SUFFIX));
    values[3] = bytes.concat(bytes32(_executionDelay));
    // Key and value for the proposal creation timestamp
    keys[4] = bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_CREATION_TIMESTAMP_SUFFIX));
    values[4] = bytes.concat(bytes32(block.timestamp));
    // Key and value for the number of choices
    keys[5] = bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_PROPOSAL_CHOICES_SUFFIX));
    values[5] = bytes.concat(bytes32(_choices));
    // Key and value for the maximum number of choises allowed per vote
    keys[6] = bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_MAXIMUM_CHOICES_PER_VOTE_SUFFIX));
    values[6] = bytes.concat(bytes32(_choicesPerVote));

    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataMultipleSelector,
        keys, values
      )
    );

    emit ProposalCreated(proposalSignature);
  }

  /**
   * @inheritdoc IDaoProposals
   */
  function getProposalHash(
    address _signer,
    bytes10 _proposalSignature,
    bytes32 _choicesBitArray
  )
    public
    override
    view
    returns(bytes32 _hash)
  {
    _hash = keccak256(abi.encodePacked(
      address(this),
      _signer,
      _proposalSignature,
      _choicesBitArray,
      votingNonce[_signer]
    ));
  }
  /**
   * @inheritdoc IDaoProposals
   */
  function executeProposal(
    bytes10 _proposalSignature,
    bytes[] calldata _signatures,
    address[] calldata _signers,
    bytes32[] calldata _choicesBitArray
  )
    external
    override
    returns(uint256[] memory)
  {
    _verifyPermission(msg.sender, _PERMISSION_EXECUTE, "EXECUTE");
    _verifyPhasesPassed(_proposalSignature);
    // Revert if one of the arrays `_signatures`, `_signers` and `_choicesBitArray` are different in length
    if (
      _signatures.length != _signers.length ||
      _signers.length != _choicesBitArray.length
    ) revert IndexedError("DaoProposals", 0x06);
    // Get maximum chices per vote
    bytes memory maximumChoicesPerVote = IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(_proposalSignature, _DAO_PROPOSAL_MAXIMUM_CHOICES_PER_VOTE_SUFFIX)));
    // Getting the array of votes per each choice
    bytes memory nrOfChoices = IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(_proposalSignature, _DAO_PROPOSAL_PROPOSAL_CHOICES_SUFFIX)));
    uint256[] memory arrayOfVotesPerChoices = new uint256[](uint256(bytes32(nrOfChoices)));
    // Verify each signer and add his choises with his delegates to `arrayOfVotesPerChoices`
    for (uint256 i = 0; i < _signatures.length; i++) {
      address recoveredAddress = _getSigRecoveredAddress(_proposalSignature, _signatures[i], _signers[i], _choicesBitArray[i]);
      // Get number of votes a user has
      uint256 userNumberOfVotes = _getUserNumberOfVotes(_proposalSignature, recoveredAddress, _signers[i]);
      if (userNumberOfVotes > 0) {
        // Add users votes to each user choice in the array of choices.
        for (uint256 j = 0; j < uint256(bytes32(maximumChoicesPerVote)); j++) {
          if (_choicesBitArray[i] & bytes32(1 << i) != 0) arrayOfVotesPerChoices[i] += userNumberOfVotes;
        }
      }
    }

    /**
     * TODO Select the winner choice/choices. execute depending on the winner choice.
     */

    // For testing purposes return the array of choices with the number of votes
    return arrayOfVotesPerChoices;

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
   * @dev Verify if all proposal phases passed.
   * Revert if check failed.
   */
  function _verifyPhasesPassed(
    bytes10 _proposalSignature
  )
    internal
    view
  {
    bytes32 creationTimestamp = bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(_proposalSignature, _DAO_PROPOSAL_CREATION_TIMESTAMP_SUFFIX))));
    bytes32 votingDelay = bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(_proposalSignature, _DAO_PROPOSAL_VOTING_DELAY_SUFFIX))));
    bytes32 votingPeriod = bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(_proposalSignature, _DAO_PROPOSAL_VOTING_PERIOD_SUFFIX))));
    bytes32 executionDelay = bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(_proposalSignature, _DAO_PROPOSAL_EXECUTION_DELAY_SUFFIX))));
    // Revert if the proposal still has some time left for one of its pahses
    if (
      uint256(creationTimestamp) +
      uint256(votingDelay) +
      uint256(votingPeriod) +
      uint256(executionDelay) >
      block.timestamp
    )  revert IndexedError("DaoProposals", 0x05);
  }

  /**
   * @dev Get the address recovered from a signature.
   *
   * @return recoveredAddress
   */
  function _getSigRecoveredAddress(
    bytes10 _proposalSignature,
    bytes memory _signature,
    address _signer,
    bytes32 _choicesBitArray
  )
    internal
    view
    returns (address recoveredAddress)
  {
    bytes32 _hash = getProposalHash(_signer, _proposalSignature, _choicesBitArray).toEthSignedMessageHash();
    recoveredAddress = _hash.recover(_signature);
  }

  /**
   * @dev Verify if the users vote is valid
   *
   * @return result
   */
  function _getUserVoteValidity(
    bytes10 _proposalSignature,
    address _recoveredAddressFromSig,
    address _userAddress
  )
    internal
    view
    returns(bool result)
  {
    result = true;
    // Revert if `recoveredAddress` is not the same as `_signers[i]` 
    if (_userAddress == _recoveredAddressFromSig) result = false;
    // Verify if user delegated his vote
    bytes memory dalegatedValue = IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(_DAO_DELEGATEE_PREFIX, bytes20(_recoveredAddressFromSig))));
    if (dalegatedValue.length == 0) result = false;
    // Verify if the user has already voted
    bytes32 votingStatusKey = bytes32(bytes.concat(_proposalSignature, bytes20(_recoveredAddressFromSig)));
    bytes memory votingStatus = IERC725Y(UNIVERSAL_PROFILE).getData(votingStatusKey);
    if (votingStatus.length == 0) result = false;
  }

  /**
   * @dev Get the number of votes a user has. Takes into account the delegates of the user.
   */
  function _getUserNumberOfVotes(
    bytes10 _proposalSignature,
    address _recoveredAddressFromSig,
    address _userAddress
  )
    internal
    view
    returns (uint256 numberOfVotes)
  {
    if (!_getUserVoteValidity(_proposalSignature, _recoveredAddressFromSig, _userAddress)) {
      numberOfVotes = 0;
    }
    else {
      numberOfVotes = 1;
      // Find if user has delegates and add the number of delegates to `numberOfVotes`
      if (_getPermissions(_recoveredAddressFromSig) & _PERMISSION_RECIEVE_DELEGATE != 0) {
        bytes memory encodedDelegatesArray = IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(_DAO_DELEGATES_ARRAY_PREFIX, bytes20(_recoveredAddressFromSig))));
        if(encodedDelegatesArray.length > 64) {
          bytes32 userNrOfDelegates;
          assembly {
            userNrOfDelegates := mload(add(encodedDelegatesArray, 64))
          }
          numberOfVotes += uint256(userNrOfDelegates);
        }
      }
    }
  }

}