// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import {LSP0ERC725Account} from "./LSP0ERC725Account.sol";
import {LSP6KeyManager} from "./LSP6KeyManager.sol";
import {DaoAccountMetadata} from "./DaoAccountMetadata.sol";
import {DaoPermissions} from "./DaoPermissions.sol";
import {DaoProposals} from "./DaoProposals.sol";
import {DaoDelegates} from "./DaoDelegates.sol";
import {DaoParticipation} from "./DaoParticipation.sol";
import {DaoVotingStrategies} from "./DaoVotingStrategies.sol";
import {DaoModifiers} from "./Utils/DaoModifiers.sol";
import {DaoUtils} from "./Utils/DaoUtils.sol";

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
   * @notice Instance for the utils of a Universal Profile DAO.
   */
  DaoUtils private utils = new DaoUtils();

  /**
   * @notice Instance of the DAO Universal Profile.
   */
  address private UNIVERSAL_PROFILE;

  /**
   * @notice Instance for the Dao Metadata smart contract.
   */
  address private DAO_METADATA;

  /**
   * @notice Instance for the Dao Permissions smart contract.
   */
  address private DAO_PERMISSIONS;

  /**
   * @notice Instance for the Dao Proposals smart contract.
   */
  address private DAO_PROPOSALS;

  /**
   * @notice Instance for the Dao Delegates smart contract.
   */
  address private DAO_DELEGATES;

  /**
   * @notice Instance for the Dao Metadata smart contract.
   */
  address private DAO_PARTICIPATION;

  /**
   * @notice Instance for the Dao Voting Strategies smart contract.
   */
  address private DAO_VOTING_STRATEGIES;

  /**
   * @notice Initialization of the Universal Profile Account as a DAO Account;
   * Here is where all the tools needed for a functioning DAO are initialized.
   */
  constructor(
    address _UNIVERSAL_PROFILE,
    address _KEY_MANAGER,
    address _DAO_METADATA,
    address _DAO_PERMISSIONS,
    address _DAO_PROPOSALS,
    address _DAO_DELEGATES,
    address _DAO_PARTICIPATION,
    address _DAO_VOTING_STRATEGIES
  )
    DaoModifiers(
      address(_DAO_METADATA),
      address(_DAO_PERMISSIONS),
      address(_DAO_PROPOSALS),
      address(_DAO_DELEGATES),
      address(_DAO_PARTICIPATION)
    )
  {
    UNIVERSAL_PROFILE = _UNIVERSAL_PROFILE;
    DAO_METADATA = _DAO_METADATA;
    DAO_METADATA.init(_UNIVERSAL_PROFILE, _KEY_MANAGER, utils, address(this));
    DAO_PERMISSIONS = _DAO_PERMISSIONS;
    DAO_PERMISSIONS.init(_UNIVERSAL_PROFILE, utils, address(this));
    DAO_PROPOSALS = _DAO_PROPOSALS;
    DAO_PROPOSALS.init(_UNIVERSAL_PROFILE, utils, address(this));
    DAO_DELEGATES = _DAO_DELEGATES;
    DAO_DELEGATES.init(_UNIVERSAL_PROFILE, utils, address(this));
    DAO_PARTICIPATION = _DAO_PARTICIPATION;
    DAO_PARTICIPATION.init(utils, address(this));
    DAO_VOTING_STRATEGIES = _DAO_VOTING_STRATEGIES;
    DAO_VOTING_STRATEGIES.init(_UNIVERSAL_PROFILE, address(this));
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
    // https://docs.lukso.tech/standards/universal-profile/lsp6-key-manager#allowed-erc725y-keys
    uint256 addressesArrayLength = DaoPermissions(DAO_PERMISSIONS)._getDaoAddressesArrayLength();
    DaoPermissions(DAO_PERMISSIONS)._setDaoAddressByIndex(addressesArrayLength, universalProfileAddress);
    DaoPermissions(DAO_PERMISSIONS)._setDaoAddressesArrayLength(addressesArrayLength + 1);

    DaoParticipation(DAO_PARTICIPATION)._setDaoToArrayByIndex(
      universalProfileAddress,
      address(this),
      uint128(DaoParticipation(DAO_PARTICIPATION)._getArrayOfDaosLength(universalProfileAddress))
    );
    DaoParticipation(DAO_PARTICIPATION)._setArrayOfDaosLength(
      universalProfileAddress,
      DaoParticipation(DAO_PARTICIPATION)._getArrayOfDaosLength(universalProfileAddress) + 1
    );
    DaoParticipation(DAO_PARTICIPATION)._toggleParticipantOfDao(universalProfileAddress, address(this), false);

    if(msg.sender != universalProfileAddress) {
      DaoParticipation(DAO_PARTICIPATION)._setControllerByIndex(
        universalProfileAddress,
        address(this),
        msg.sender,
        uint128(DaoParticipation(DAO_PARTICIPATION)._getControllersArrayLength(universalProfileAddress, address(this)))
      );
      DaoParticipation(DAO_PARTICIPATION)._setControllersArrayLength(
        universalProfileAddress,
        address(this),
        DaoParticipation(DAO_PARTICIPATION)._getControllersArrayLength(universalProfileAddress, address(this)) + 1
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
    permissionSet(msg.sender, DaoPermissions(DAO_PERMISSIONS)._getPermissionsByIndex(4)) /** @dev User has MASTER permission */
    permissionUnset(universalProfileAddress, DaoPermissions(DAO_PERMISSIONS)._getPermissionsByIndex(index))
  {
    if (!DAO_PARTICIPATION._getParticipantOfDao(universalProfileAddress, address(this))) {
      registerUser(universalProfileAddress);
    }
    
    DaoPermissions(DAO_PERMISSIONS)._setAddressDaoPermission(universalProfileAddress, index, true);
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
    permissionSet(universalProfileAddress, DAO_PERMISSIONS._getPermissionsByIndex(4)) /** @dev User has MASTER permission */
    permissionSet(universalProfileAddress, DAO_PERMISSIONS._getPermissionsByIndex(index))
  {
    DAO_PERMISSIONS._setAddressDaoPermission(universalProfileAddress, index, false);
  }

  /**
   * @notice Delegate your vote to another participant of the DAO
   */
  function delegate(address delegatee)
    external
    permissionSet(msg.sender, DAO_PERMISSIONS._getPermissionsByIndex(2))
    permissionSet(delegatee, DAO_PERMISSIONS._getPermissionsByIndex(3))
  {
    DAO_DELEGATES._setDelegateeOfTheDelegator(msg.sender, delegatee);
    DAO_DELEGATES._setDelegatorByIndex(
      msg.sender,
      delegatee,
      DAO_DELEGATES._getDelegatorsArrayLength(delegatee)
    );
    DAO_DELEGATES._setDelegatorsArrayLength(
      DAO_DELEGATES._getDelegatorsArrayLength(delegatee),
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
    permissionSet(msg.sender, DAO_PERMISSIONS._getPermissionsByIndex(1))
    returns(bytes10 proposalSignature)
  {
    require(targets.length == datas.length, "Provided targets and datas have different lengths.");

    proposalSignature = DAO_PROPOSALS._getProposalSignature(block.timestamp, title);

    DAO_PROPOSALS._setAttributeValue(
      proposalSignature,
      DAO_PROPOSALS._getProposalAttributeKeyByIndex(0),
      bytes(title)
    );
    DAO_PROPOSALS._setAttributeValue(
      proposalSignature,
      DAO_PROPOSALS._getProposalAttributeKeyByIndex(1),
      bytes(description)
    );
    DAO_PROPOSALS._setAttributeValue(
      proposalSignature,
      DAO_PROPOSALS._getProposalAttributeKeyByIndex(2),
      bytes.concat(bytes32(block.timestamp))
    );
    DAO_PROPOSALS._setAttributeValue(
      proposalSignature,
      DAO_PROPOSALS._getProposalAttributeKeyByIndex(3),
      bytes.concat(bytes32(block.timestamp + DAO_METADATA._getDaoVotingDelay()))
    );
    DAO_PROPOSALS._setAttributeValue(
      proposalSignature,
      DAO_PROPOSALS._getProposalAttributeKeyByIndex(4),
      bytes.concat(bytes32(block.timestamp + DAO_METADATA._getDaoVotingPeriod()))
    );

    DAO_PROPOSALS._setTargetsAndDatas(proposalSignature, targets, datas);
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
    DAO_PROPOSALS._setAttributeValue(proposalSignature, DAO_PROPOSALS._getProposalAttributeKeyByIndex(4), bytes.concat(bytes32(block.timestamp)));
  
    (address[] memory targets, bytes[] memory datas) = DAO_PROPOSALS._getTargetsAndDatas(proposalSignature);
    if(DAO_VOTING_STRATEGIES._strategyOneResult(proposalSignature)) {
      for (uint i = 0; i < targets.length; i++) {
        UNIVERSAL_PROFILE.execute(
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
    permissionSet(msg.sender, DAO_PERMISSIONS._getPermissionsByIndex(0))
    didNotDelegate(msg.sender)
    didNotVote(msg.sender, proposalSignature)
    votingPeriodIsOn(proposalSignature)
  {
    bytes20 votesKey = DAO_PROPOSALS._getProposalAttributeKeyByIndex(7 + voteIndex);
    uint256 votes;
    if(uint256(bytes32(DAO_PERMISSIONS._getAddressDaoPermission(msg.sender))) & (1 << 3) !=0) {
      votes = uint256(bytes32(DAO_PROPOSALS._getAttributeValue(proposalSignature, votesKey ))) + DAO_DELEGATES._getDelegatorsArrayLength(msg.sender);
    }
    else {
      votes = uint256(bytes32(DAO_PROPOSALS._getAttributeValue(proposalSignature, votesKey))) + 1;
    }
    DAO_PROPOSALS._setAttributeValue(
      proposalSignature,
      votesKey,
      bytes.concat(bytes32(votes))
    );
  }

}