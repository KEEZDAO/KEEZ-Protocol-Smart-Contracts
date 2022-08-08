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

  _DAO_PROPOSAL_SIGNATURE,
  _DAO_PROPOSAL_JSON_METADATA_SUFFIX,
  _DAO_PROPOSAL_VOTING_DELAY_SUFFIX,
  _DAO_PROPOSAL_VOTING_PERIOD_SUFFIX,
  _DAO_PROPOSAL_CREATION_TIMESTAMP_SUFFIX,
  _DAO_PROPOSAL_PAYLOADS_ARRAY_SUFFIX,
  _DAO_PROPOSAL_PROPOSAL_CHOICES_SUFFIX,
  _DAO_PROPOSAL_MAXIMUM_CHOICES_PER_VOTE_SUFFIX,
  _KEY_PARTICIPANT_VOTE
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
 * @custom:version 1.3
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
    uint48 _votingDelay,
    uint48 _votingPeriod,
    bytes[] calldata _payloads,
    uint8 _choices,
    uint8 _choicesPerVote
  )
    external
    override
  {
    _verifyPermission(msg.sender, _PERMISSION_PROPOSE, "PROPOSE");
    if (_choices > 16) revert IndexedError("DAO", 0x03);
    if (_choicesPerVote > _choices) revert IndexedError("DAO", 0x04);
    if (_votingDelay < uint48(bytes6(IERC725Y(UNIVERSAL_PROFILE).getData(_DAO_MINIMUM_VOTING_DELAY_KEY)))) revert IndexedError("DAO", 0x05);
    if (_votingPeriod < uint48(bytes6(IERC725Y(UNIVERSAL_PROFILE).getData(_DAO_MINIMUM_VOTING_PERIOD_KEY)))) revert IndexedError("DAO", 0x06);

    bytes10 proposalSignature = _DAO_PROPOSAL_SIGNATURE(
      bytes6(keccak256(abi.encode(_title, block.timestamp)))
    );
    bytes32[] memory keys = new bytes32[](7);
    bytes[] memory values = new bytes[](7);

    if(_payloads.length > 0){
      keys[0] = bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_PAYLOADS_ARRAY_SUFFIX));
      values[0] = abi.encode(_payloads);
    }

    keys[1] = bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_JSON_METADATA_SUFFIX));
    values[1] = bytes(_metadataLink);

    keys[2] = bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_VOTING_DELAY_SUFFIX));
    values[2] = bytes.concat(bytes6(uint48(_votingDelay)));

    keys[3] = bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_VOTING_PERIOD_SUFFIX));
    values[3] = bytes.concat(bytes6(uint48(_votingPeriod)));

    keys[4] = bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_CREATION_TIMESTAMP_SUFFIX));
    values[4] = bytes.concat(bytes6(uint48(block.timestamp)));

    keys[5] = bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_PROPOSAL_CHOICES_SUFFIX));
    values[5] = bytes.concat(bytes1(_choices));

    keys[6] = bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_MAXIMUM_CHOICES_PER_VOTE_SUFFIX));
    values[6] = bytes.concat(bytes1(_choicesPerVote));

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
    bool _response
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
      _response,
      votingNonce[_signer]
    ));
  }

















  // TODO Fix the execute proposal method according to multisg
  // Keep in mind signatures and the deleagted votes
  // As well as the choices of each voter.


  /**
   * @inheritdoc IDaoProposals
   */
  function executeProposal(
    bytes10 proposalSignature,
    bytes[] calldata _signatures,
    address[] calldata _signers
  )
    external
    override
  {
    _verifyPermission(msg.sender, _PERMISSION_EXECUTE, "EXECUTE");
    if (
      uint256(uint48(bytes6(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_CREATION_TIMESTAMP_SUFFIX))))))
      + uint256(uint48(bytes6(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_VOTING_DELAY_SUFFIX))))))
      + uint256(uint48(bytes6(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_VOTING_PERIOD_SUFFIX))))))
      > block.timestamp
    ) revert IndexedError("DAO", 0x06);
    if (
      uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(
        bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_MAXIMUM_CHOICES_PER_VOTE_SUFFIX))
      ))) == 0
    ) revert IndexedError("DAO", 0x07);

    /**
     * @dev Count all the votes by accessing the choices of all of the participants
     * of the DAO.
     * 1. Get the user address and verify its permissions.
     * 2. If `user` has vote permission or send delegate permission
     * we will save his number of votes as 1 and save his choices.
     */  
    uint8 nrOfChoices =  uint8(bytes1(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_PROPOSAL_CHOICES_SUFFIX)))));
    uint256 totalUsers = uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY)));
    uint256[] memory votesByChoiceIndex = new uint256[](nrOfChoices);
    for (uint128 i = 0; i < totalUsers; i++) {
      address user = address(bytes20(IERC725Y(UNIVERSAL_PROFILE).getData(
        bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(i)))
      )));
      bytes32 permissions = _getPermissions(user);
      if (permissions & _PERMISSION_VOTE != 0 || permissions & _PERMISSION_SEND_DELEGATE != 0) {
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

    uint256 majority = uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(_DAO_MAJORITY_KEY)));
    uint256 participationRate = uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(
      _DAO_PARTICIPATION_RATE_KEY
    )));

    /**
     * @dev Check if the proposal has passed and execute the saved methods.
     */
    if(
      totalVotes/totalUsers > participationRate/totalUsers &&
      positiveVotes/totalVotes > majority/totalVotes
    ) {
      bytes memory encodedPayloadArray = IERC725Y(UNIVERSAL_PROFILE).getData(
        bytes32(bytes.concat(proposalSignature, _DAO_PROPOSAL_PAYLOADS_ARRAY_SUFFIX))
      );
      bytes[] memory payloads = abi.decode(encodedPayloadArray, (bytes[]));
      for (uint256 i = 0; i < payloads.length; i++) {
        ILSP6KeyManager(KEY_MANAGER).execute(payloads[i]);
      }
    }

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

}