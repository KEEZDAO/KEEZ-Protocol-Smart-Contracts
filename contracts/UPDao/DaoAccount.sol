// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import "./DaoAccountMetadata.sol";
import "./DaoPermissions.sol";
import "./DaoProposals.sol";
import "./DaoVotingStrategies.sol";
import "./DaoDelegates.sol";
import "./DaoParticipation.sol";
import "./Utils/DaoModifiers.sol";
import "./Utils/DaoUtils.sol";

/**
 *
* @notice This smart contract is responsible for connecting all the necessary tools for
* a DAO based on Universal Profiles (LSP0ERC725Account)
 *
 * @author B00ste
 * @title DaoAccount
 * @custom:version 0.92
 */
contract DaoAccount is DaoModifiers {
   
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
   * @notice Instance for the Dao Metadata smart contract.
   */
  DaoAccountMetadata private metadata;

  /**
   * @notice Instance for the Dao Permissions smart contract.
   */
  DaoPermissions private permissions;

  /**
   * @notice Instance for the Dao Proposals smart contract.
   */
  DaoProposals private proposals;

  /**
   * @notice Instance for the Dao Voting Strategies smart contract.
   */
  DaoVotingStrategies private strategies;

  /**
   * @notice Instance for the Dao Delegates smart contract.
   */
  DaoDelegates private delegates;

  /**
   * @notice Instance for the Dao Metadata smart contract.
   */
  DaoParticipation private participation;

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
    uint256 votingPeriod,
    address[6] memory daoAddresses
  )
    DaoModifiers(
      daoAddresses[0],
      daoAddresses[1],
      daoAddresses[2],
      daoAddresses[3],
      daoAddresses[4]
    )
  {
    require(quorum >= 0 && quorum <= 100);
    require(participationRate >= 0 && participationRate <= 100);

    metadata = DaoAccountMetadata(daoAddresses[0]);
    metadata.init(DAO, utils, address(this));
    permissions = DaoPermissions(daoAddresses[1]);
    permissions.init(DAO, utils, address(this));
    proposals = DaoProposals(daoAddresses[2]);
    proposals.init(DAO, utils, address(this));
    delegates = DaoDelegates(daoAddresses[3]);
    delegates.init(DAO, utils, address(this));
    participation = DaoParticipation(daoAddresses[4]);
    participation.init(utils, address(this));
    strategies = DaoVotingStrategies(daoAddresses[5]);
    strategies.init(DAO, address(this));

    metadata._setDaoName(name);
    metadata._setDaoDescription(description);
    metadata._setDaoMajority(quorum);
    metadata._setDaoParticipationRate(participationRate);
    metadata._setDaoVotingDelay(votingDelay);
    metadata._setDaoVotingPeriod(votingPeriod);
  }

  // --- GENERAL METHODS

  /**
   * @notice Register the user for this Dao. 
   * Setup the necessary permissions.
   * Initializing the necessary arrays.
   * Sets the `msg.sender` as the dao controller address for the `universalProfileAddress` if `msg.sender` != `universalProfileAddress`
   */
  function registerUser(address universalProfileAddress) internal {
    //IERC725Y UP = IERC725Y(universalProfileAddress);
    //todo add address(this) to the controller addresses of `universalProfileAddress` and set the 'setData' permission to 1 for address(this). 
    uint256 addressesArrayLength = permissions._getDaoAddressesArrayLength();
    permissions._setDaoAddressByIndex(addressesArrayLength, universalProfileAddress);
    permissions._setDaoAddressesArrayLength(addressesArrayLength + 1);

    participation._setDaoToArrayByIndex(
      universalProfileAddress,
      address(this),
      uint128(participation._getArrayOfDaosLength(universalProfileAddress))
    );
    participation._setArrayOfDaosLength(
      universalProfileAddress,
      participation._getArrayOfDaosLength(universalProfileAddress) + 1
    );
    participation._toggleParticipantOfDao(universalProfileAddress, address(this), false);

    if(msg.sender != universalProfileAddress) {
      participation._setControllerByIndex(
        universalProfileAddress,
        address(this),
        msg.sender,
        uint128(participation._getControllersArrayLength(universalProfileAddress, address(this)))
      );
      participation._setControllersArrayLength(
        universalProfileAddress,
        address(this),
        participation._getControllersArrayLength(universalProfileAddress, address(this)) + 1
      );
    }
  }
  
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
    permissionSet(msg.sender, permissions._getPermissionsByIndex(4)) /** @dev User has MASTER permission */
    permissionUnset(universalProfileAddress, permissions._getPermissionsByIndex(index))
  {
    if (!participation._getParticipantOfDao(universalProfileAddress, address(this))) {
      registerUser(universalProfileAddress);
    }
    
    permissions._setAddressDaoPermission(universalProfileAddress, index, true);
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
    permissionSet(universalProfileAddress, permissions._getPermissionsByIndex(4)) /** @dev User has MASTER permission */
    permissionSet(universalProfileAddress, permissions._getPermissionsByIndex(index))
  {
    permissions._setAddressDaoPermission(universalProfileAddress, index, false);
  }

  /**
   * @notice Delegate your vote to another participant of the DAO
   */
  function delegate(address delegatee)
    external
    permissionSet(msg.sender, permissions._getPermissionsByIndex(2))
    permissionSet(delegatee, permissions._getPermissionsByIndex(3))
  {
    delegates._setDelegateeOfTheDelegator(msg.sender, delegatee);
    delegates._setDelegatorByIndex(
      msg.sender,
      delegatee,
      delegates._getDelegatorsArrayLength(delegatee)
    );
    delegates._setDelegatorsArrayLength(
      delegates._getDelegatorsArrayLength(delegatee),
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
    permissionSet(msg.sender, permissions._getPermissionsByIndex(1))
    returns(bytes10 proposalSignature)
  {
    require(targets.length == datas.length, "Provided targets and datas have different lengths.");

    proposalSignature = proposals._getProposalSignature(block.timestamp, title);

    proposals._setAttributeValue(
      proposalSignature,
      proposals._getProposalAttributeKeyByIndex(0),
      bytes(title)
    );
    proposals._setAttributeValue(
      proposalSignature,
      proposals._getProposalAttributeKeyByIndex(1),
      bytes(description)
    );
    proposals._setAttributeValue(
      proposalSignature,
      proposals._getProposalAttributeKeyByIndex(2),
      bytes.concat(bytes32(block.timestamp))
    );
    proposals._setAttributeValue(
      proposalSignature,
      proposals._getProposalAttributeKeyByIndex(3),
      bytes.concat(bytes32(block.timestamp + metadata._getDaoVotingDelay()))
    );
    proposals._setAttributeValue(
      proposalSignature,
      proposals._getProposalAttributeKeyByIndex(4),
      bytes.concat(bytes32(block.timestamp + metadata._getDaoVotingPeriod()))
    );

    proposals._setTargetsAndDatas(proposalSignature, targets, datas);
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
    isParticipantOfDao(msg.sender, address(this))
  {
    proposals._setAttributeValue(proposalSignature, proposals._getProposalAttributeKeyByIndex(4), bytes.concat(bytes32(block.timestamp)));
  
    (address[] memory targets, bytes[] memory datas) = proposals._getTargetsAndDatas(proposalSignature);
    if(strategies._strategyOneResult(proposalSignature)) {
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
    permissionSet(msg.sender, permissions._getPermissionsByIndex(0))
    didNotDelegate(msg.sender)
    didNotVote(msg.sender, proposalSignature)
    votingPeriodIsOn(proposalSignature)
  {
    bytes20 votesKey = proposals._getProposalAttributeKeyByIndex(7 + voteIndex);
    uint256 votes;
    if(uint256(bytes32(permissions._getAddressDaoPermission(msg.sender))) & (1 << 3) !=0) {
      votes = uint256(bytes32(proposals._getAttributeValue(proposalSignature, votesKey ))) + delegates._getDelegatorsArrayLength(msg.sender);
    }
    else {
      votes = uint256(bytes32(proposals._getAttributeValue(proposalSignature, votesKey))) + 1;
    }
    proposals._setAttributeValue(
      proposalSignature,
      votesKey,
      bytes.concat(bytes32(votes))
    );
  }

}