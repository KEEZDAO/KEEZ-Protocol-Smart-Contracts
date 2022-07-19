// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
import "./DaoAccountMetadata.sol";
import "./DaoPermissions.sol";
import "./DaoProposals.sol";
import "./VotingStrategies.sol";
import "./DaoDelegates.sol";
import "./DaoUtils.sol";

/**
 *
* @notice This smart contract is responsible for connecting all the necessary tools for
* a DAO based on Universal Profiles (LSP0ERC725Account)
 *
 * @author B00ste
 * @title DaoAccount
 * @custom:version 0.9
 */
abstract contract DaoAccount is DaoAccountMetadata, DaoPermissions, DaoProposals, VotingStrategies, DaoDelegates {
   
  /**
   * @notice Unique instance of the DAO Universal Profile.
   */
  LSP0ERC725Account private DAO = new LSP0ERC725Account(address(this));

  /**
   * @notice Instance for the utils of a Universal Profile DAO.
   */
  DaoUtils private utils = new DaoUtils();

  /**
   * @notice Initialization of the Universal Profile Account as a DAO Account;
   * This smart contract will be given all controller permissions.
   * Here is where all the tools needed for a functioning DAO are initialized.
   *
   * @param name Name of the DAO.
   * @param description Description of the DAO.
   * @param quorum The percentage of pro votes from the sum of pro and against votes needed for a proposal to pass.
   * @param participationRate The percentage of pro and against votes compared to abstain votes needed for a proposal to pass.
   * @param votingDelay Time required to pass before a proposal goes to the voting phase.
   * @param votingPeriod Time allowed for voting on a proposal.
   */
  constructor(
    string memory name,
    string memory description,
    uint8 quorum,
    uint8 participationRate,
    uint256 votingDelay,
    uint256 votingPeriod
  )
    DaoPermissions(DAO, utils)
    DaoProposals(DAO, utils, address(this))
    VotingStrategies(address(this))
    DaoDelegates(DAO, utils)
  {

    require(quorum >= 0 && quorum <= 100);
    require(participationRate >= 0 && participationRate <= 100);

    _setDaoName(name);
    _setDaoDescription(description);
    _setDaoQuorum(quorum);
    _setDaoParticipationRate(participationRate);
    _setDaoVotingDelay(votingDelay);
    _setDaoVotingPeriod(votingPeriod);

    _setDaoAddressesArrayLength(0);
    _setProposalsArrayLength(0, 1);
    _setProposalsArrayLength(0, 2);
    _setProposalsArrayLength(0, 3);

    bytes32[] memory keysArray = new bytes32[](3);
    // Controller addresses array key
    keysArray[0] = bytes32(0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3);
    // First element from controller addresses array key
    keysArray[1] = bytes32(bytes.concat(bytes16(0xdf30dba06db6a30e65354d9a64c60986), bytes16(0)));
    // This addresses permissions key
    keysArray[2] = bytes32(bytes.concat(bytes12(0x4b80742de2bf82acb3630000), bytes20(address(this))));


    bytes[] memory valuesArray = new bytes[](3);
    // Controller addresses array value
    valuesArray[0] = bytes.concat(bytes32(uint256(1)));
    // First element from controller addresses array value
    valuesArray[1] = bytes.concat(bytes20(address(this)));
    // This addresses permissions value
    valuesArray[2] = bytes.concat(bytes32(0x0000000000000000000000000000000000000000000000000000000000007FFF));

    DAO.setData(keysArray, valuesArray);
  }

  // --- GENERAL METHODS
  
  /**
   * @notice Add permission to an address by index.
   * Index 0 sets the VOTE permission.
   * Index 1 sets the PROPOSE permission.
   * Index 2 sets the SEND_DELEGATE permission.
   * Index 3 sets the RECIEVE_DELEGATE permission.
   * Index 4 sets the MASTER permission.
   *
   * @param universalProfileAddress The address of a Universal Profile.
   * @param index A number 0 <= `index` <= 4.
   */
  function addPermission(
    address universalProfileAddress,
    uint8 index
  ) 
    external
    permissionSet(universalProfileAddress, _getPermissionsByIndex(4)) /** @dev User has MASTER permission */
    permissionUnset(universalProfileAddress, _getPermissionsByIndex(index))
  {
    if (!checkUser(universalProfileAddress)) {
      uint256 addressesArrayLength = _getDaoAddressesArrayLength();
      _setDaoAddressByIndex(addressesArrayLength, universalProfileAddress);
      _setDaoAddressesArrayLength(addressesArrayLength + 1);
    }
    
    _setAddressDaoPermission(universalProfileAddress, index, true);
  }

  /**
   * @notice Remove the permission of an Unversal Profile by index.
   * Index 0 unsets the VOTE permission.
   * Index 1 unsets the PROPOSE permission.
   * Index 2 unsets the SEND_DELEGATE permission.
   * Index 3 unsets the RECIEVE_DELEGATE permission.
   * Index 4 unsets the MASTER permission.
   *
   * @param universalProfileAddress The address of a Universal Profile.
   * @param index A number 0 <= `index` <= 4.
   */

  function removePermission(
    address universalProfileAddress,
    uint8 index
  ) 
    external
    permissionSet(universalProfileAddress, _getPermissionsByIndex(4)) /** @dev User has MASTER permission */
    permissionSet(universalProfileAddress, _getPermissionsByIndex(index))
  {
    _setAddressDaoPermission(universalProfileAddress, index, false);
  }

  /**
   * @notice Delegate your vote to another participant of the DAO
   */
  function delegate(address delegator, address delegatee)
    external
    permissionSet(delegator, _getPermissionsByIndex(2))
    permissionSet(delegatee, _getPermissionsByIndex(3))
  {
    _setDelegateeOfTheDelegator(delegator, delegatee);
    _setDelegatorByIndex(
      delegator,
      delegatee,
      _getDelegatorsArrayLength(delegatee)
    );
    _setDelegatorsArrayLength(
      _getDelegatorsArrayLength(delegatee),
      delegatee
    );
  }

  /**
   * @notice Create a proposal.
   * The proposal signature is encoded to a bytes32 variable using
   * abi.encode(_title, _description, _targets, _datas).
   *
   * @param _title Title of the proposal.
   * @param _description Description of the proposal.
   * @param _targets The addresses of the smart contracts that might have calldata executed.
   * @param _datas The calldata that will be executed if the proposall passes.
   */
  function createProposal(
    string memory _title,
    string memory _description,
    address[] memory _targets,
    bytes[] memory _datas
  )
    external
    permissionSet(msg.sender, _getPermissionsByIndex(1))
    returns(bytes32 proposalSignature)
  {
    require(_targets.length == _datas.length, "Provided targets and datas have different lengths.");

    proposalSignature = bytes32(keccak256(
      abi.encode(
        _title,
        _description,
        block.timestamp
    )));

    proposals[proposalSignature].title = _title;
    proposals[proposalSignature].description = _description;
    proposals[proposalSignature].targets = _targets;
    proposals[proposalSignature].datas = _datas;
    proposals[proposalSignature].phase = 1;
    proposals[proposalSignature].creationTimestamp = block.timestamp;

    _saveProposal(proposalSignature, 1);
  }

  /**
   * @notice Move the proposal to the voting phase.
   *
   * @param proposalSignature The abi.encode bytes32 signature of a proposal.
   */
  function putProposalToVote(
    bytes32 proposalSignature
  ) 
    external
    checkPhase(proposalSignature, (1 << 0))
    votingDelayPassed(proposalSignature)
    isParticipantOfDao(msg.sender)
  {
    proposals[proposalSignature].phase = 2;
    proposals[proposalSignature].votingTimestamp = block.timestamp;
    _saveProposal(proposalSignature, 2);
    _removeProposal(proposalSignature, 1);
  }

  /**
   * @notice End proposal and execute the calldata.
   * Encode the proposal info, timestamps and results and save them to the Universal Profile of the DAO.
   *
   * @param proposalSignature The abi.encode bytes32 signature of a proposal.
   */
  function endProposal(
    bytes32 proposalSignature
  ) 
    external
    checkPhase(proposalSignature, (1 << 1))
    votingPeriodPassed(proposalSignature)
    isParticipantOfDao(msg.sender)
  {
    proposals[proposalSignature].phase = 3;
    proposals[proposalSignature].endTimestamp = block.timestamp;
    _saveProposal(proposalSignature, 3);
    _removeProposal(proposalSignature, 2);
    delete proposals[proposalSignature];
  
    if(_strategyOneResult(proposalSignature)) {
      for (uint i = 0; i < proposals[proposalSignature].targets.length; i++) {
        DAO.execute(
          0,
          proposals[proposalSignature].targets[i],
          0,
          proposals[proposalSignature].datas[i]
        );
      }
    }
  }

  /**
   * @notice Vote on a proposal.
   *
   * @param proposalSignature The abi.encode bytes32 signature of a proposal.
   * @param voteIndex a number 0 <= `voteIndex` <= 2.
   * Index 0 are the against votes. 
   * Index 1 are the pro votes. 
   * Index 2 are the abstain votes. 
   */
  function vote(
    bytes32 proposalSignature,
    uint8 voteIndex
  )
    external
    permissionSet(msg.sender, _getPermissionsByIndex(0))
    didNotDelegate(msg.sender)
    checkPhase(proposalSignature, (1 << 1))
    votingPeriodIsOn(proposalSignature)
  {
    if(uint256(bytes32(_getAddressDaoPermission(msg.sender))) & (1 << 3) !=0) {
      if(voteIndex != 2) {
        uint256 totalVotes = _getDelegatorsArrayLength(msg.sender);
        proposals[proposalSignature].votes[voteIndex] += totalVotes;
        proposals[proposalSignature].votes[2] -= totalVotes;
      }
    }
    else {
      if(voteIndex != 2) {
        proposals[proposalSignature].votes[voteIndex] ++;
        proposals[proposalSignature].votes[2] --;
      }
    }
  }

}