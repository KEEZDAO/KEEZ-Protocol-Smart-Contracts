// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
import "./DaoAccountMetadata.sol";
import "./DaoPermissions.sol";
import "./DaoProposals.sol";
import "./DaoVotingStrategies.sol";
import "./DaoDelegates.sol";
import "./DaoUtils.sol";

/**
 *
* @notice This smart contract is responsible for connecting all the necessary tools for
* a DAO based on Universal Profiles (LSP0ERC725Account)
 *
 * @author B00ste
 * @title DaoAccount
 * @custom:version 0.91
 */
abstract contract DaoAccount is DaoAccountMetadata, DaoPermissions, DaoProposals, DaoVotingStrategies, DaoDelegates {
   
  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId)
    public
    pure
    returns (bool)
  {
    return interfaceId == bytes4(keccak256("UniversalProfileDaoAccount"));
}

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
    DaoAccountMetadata(DAO)
    DaoPermissions(DAO, utils)
    DaoProposals(DAO, utils, address(this))
    DaoVotingStrategies(DAO, address(this))
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
    public
    permissionSet(msg.sender, _getPermissionsByIndex(4)) /** @dev User has MASTER permission */
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
  function delegate(address delegatee)
    external
    permissionSet(msg.sender, _getPermissionsByIndex(2))
    permissionSet(delegatee, _getPermissionsByIndex(3))
  {
    _setDelegateeOfTheDelegator(msg.sender, delegatee);
    _setDelegatorByIndex(
      msg.sender,
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
   * The proposal signature is encoded to a bytes10 variable.
   * Which is later used compined with an attribute key for getting the attribute value.
   *
   * @param title Title of the proposal.
   * @param description Description of the proposal.
   * @param targets The addresses of the smart contracts that might have calldata executed.
   * @param datas The calldata that will be executed if the proposall passes.
   */
  function createProposal(
    string memory title,
    string memory description,
    address[] memory targets,
    bytes[] memory datas
  )
    external
    permissionSet(msg.sender, _getPermissionsByIndex(1))
    returns(bytes10 proposalSignature)
  {
    require(targets.length == datas.length, "Provided targets and datas have different lengths.");

    proposalSignature = _getProposalSignature(block.timestamp, title);
    _setAttributeValue(proposalSignature, proposalAttributeKeys[0], bytes(title));
    _setAttributeValue(proposalSignature, proposalAttributeKeys[1], bytes(description));
    _setAttributeValue(proposalSignature, proposalAttributeKeys[2], bytes.concat(bytes32(block.timestamp)));
    _setTargetsAndDatas(proposalSignature, targets, datas);
  }

  /**
   * @notice Move the proposal to the voting phase. Save the current timestamp.
   *
   * @param proposalSignature The bytes10 signature of a proposal.
   */
  function putProposalToVote(
    bytes10 proposalSignature
  ) 
    external
    votingDelayPassed(proposalSignature)
    isParticipantOfDao(msg.sender)
  {
    _setAttributeValue(proposalSignature, proposalAttributeKeys[3], bytes.concat(bytes32(block.timestamp)));
  }

  /**
   * @notice End proposal and execute the calldata.
   * Encode the proposal info, timestamps and results and save them to the Universal Profile of the DAO.
   *
   * @param proposalSignature The abi.encode bytes32 signature of a proposal.
   */
  function endProposal(
    bytes10 proposalSignature
  ) 
    external
    votingPeriodPassed(proposalSignature)
    isParticipantOfDao(msg.sender)
  {
    _setAttributeValue(proposalSignature, proposalAttributeKeys[4], bytes.concat(bytes32(block.timestamp)));
  
    (address[] memory targets, bytes[] memory datas) = _getTargetsAndDatas(proposalSignature);
    if(_strategyOneResult(proposalSignature)) {
      for (uint i = 0; i < targets.length; i++) {
        DAO.execute(
          0,
          targets[i],
          0,
          datas[i]
        );
      }
    }
  }

  /**
   * @notice Vote on a proposal.
   *
   * @param proposalSignature The abi.encode bytes32 signature of a proposal.
   * @param voteIndex a number 0 <= `voteIndex` <= 1.
   * Index 0 are the against votes. 
   * Index 1 are the pro votes. 
   */
  function vote(
    bytes10 proposalSignature,
    uint8 voteIndex
  )
    external
    permissionSet(msg.sender, _getPermissionsByIndex(0))
    didNotDelegate(msg.sender)
    didNotVote(msg.sender, proposalSignature)
    votingPeriodIsOn(proposalSignature)
  {
    if(uint256(bytes32(_getAddressDaoPermission(msg.sender))) & (1 << 3) !=0) {
      uint256 totalVotes = _getDelegatorsArrayLength(msg.sender);
      _setAttributeValue(
        proposalSignature,
        proposalAttributeKeys[7 + voteIndex],
        bytes.concat(bytes32(
          uint256(bytes32(_getAttributeValue(proposalSignature, proposalAttributeKeys[7 + voteIndex]))) + totalVotes
        ))
      );
    }
    else {
      _setAttributeValue(
        proposalSignature,
        proposalAttributeKeys[7 + voteIndex],
        bytes.concat(bytes32(
          uint256(bytes32(_getAttributeValue(proposalSignature, proposalAttributeKeys[7 + voteIndex]))) + 1
        ))
      );
    }
  }

}