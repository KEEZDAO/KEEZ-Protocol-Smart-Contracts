// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;
import "../Interfaces/DaoAccountMetadataInterface.sol";
import "../Interfaces/DaoDelegatesInterface.sol";
import "../Interfaces/DaoPermissionsInterface.sol";
import "../Interfaces/DaoProposalsInterface.sol";
import "../Interfaces/DaoParticipationInterface.sol";

contract DaoModifiers {

  /**
   * @notice Instance for the DAO metadata.
   */
  DaoAccountMetadataInterface private metadata;

  /**
   * @notice Instance for the DAO delegates.
   */
  DaoDelegatesInterface private delegates;

  /**
   * @notice Instance for the DAO permissions.
   */
  DaoPermissionsInterface private permissions;

  /**
   * @notice Instance for the DAO proposals.
   */
  DaoProposalsInterface private proposals;

  /**
   * @notice Instance for the DAO participation.
   */
  DaoParticipationInterface private participation;

  constructor(
    address metadataAddress,
    address delegatesAddress,
    address permissionsAddress,
    address proposalsAddress,
    address participationAddress
  ) {
    metadata = DaoAccountMetadataInterface(metadataAddress);
    delegates = DaoDelegatesInterface(delegatesAddress);
    permissions = DaoPermissionsInterface(permissionsAddress);
    proposals = DaoProposalsInterface(proposalsAddress);
    participation = DaoParticipationInterface(participationAddress);
  }

  /**
   * @notice Verifies if an Universal Profile has a certain permision.
   */
  modifier permissionSet(address universalProfileAddress, bytes32 checkedPermission) {
    bytes memory addressPermissions = permissions._getAddressDaoPermission(universalProfileAddress);
    require(
      uint256(bytes32(addressPermissions)) & uint256(checkedPermission) == uint256(checkedPermission),
      "User doesen't have the permission."
    );
    _;
  }

  /**
   * @notice Verifies if an Universal Profile doesn't have a certian permission.
   */
  modifier permissionUnset(address universalProfileAddress, bytes32 checkedPermission) {
    bytes memory addressPermissions = permissions._getAddressDaoPermission(universalProfileAddress);
    require(
      uint256(bytes32(addressPermissions)) & uint256(checkedPermission) == 0,
      "User already has the permission."
    );
    _;
  }

  /**
   * @notice Verifying if the voting delay has passed. 
   */
  modifier votingDelayPassed(bytes10 proposalSignature) {
    require(
      metadata._getDaoVotingDelay() + uint256(bytes32(proposals._getAttributeValue(proposalSignature, proposals._getProposalAttributeKeyByIndex(2)))) < block.timestamp,
      "The voting delay is not yeat over."
    );
    _;
  }

  /**
   * @notice Verifying if the voting period has passed. 
   */
  modifier votingPeriodPassed(bytes10 proposalSignature) {
    require(
      metadata._getDaoVotingPeriod() + uint256(bytes32(proposals._getAttributeValue(proposalSignature, proposals._getProposalAttributeKeyByIndex(3)))) < block.timestamp,
      "The voting delay is not yet over."
    );
    _;
  }

  /**
   * @notice Verifying if the voting period is still on.
   */
  modifier votingPeriodIsOn(bytes10 proposalSignature) {
    require(
      metadata._getDaoVotingPeriod() + uint256(bytes32(proposals._getAttributeValue(proposalSignature, proposals._getProposalAttributeKeyByIndex(3)))) > block.timestamp,
      "Voting period is already over."
    );
    _;
  }

  /**
   * @notice Verifying if the user didn't vote.
   */
  modifier didNotVote(address universalProfileAddress, bytes10 proposalSignature) {
    require(
      !proposals._getVotedStatus(universalProfileAddress, proposalSignature),
      "User did already vote."
    );
    _;
  }

  /**
   * @notice Verifies that a Universal Profile did not delegate his vote.
   */ 
  modifier didNotDelegate(address universalProfileAddress) {
    address delegatee = delegates._getDelegateeOfTheDelegator(universalProfileAddress);
    require(
      universalProfileAddress == delegatee || bytes20(universalProfileAddress) == bytes20(0),
      "User delegated his votes."
    );
    _;
  }

  /**
   * @notice Verifies if a `universalProfileAddress` is a participant of the Dao.
   */
  modifier isParticipantOfDao(address universalProfileAddress, address daoAddress) {
    require(
      participation._getParticipantOfDao(universalProfileAddress, daoAddress),
      "Universal Profile is not a participant of the DAO."
    );
    _;
  }

  /**
   * @notice Verifies if `msg.sender` is a controller of the `universalProfileAddress` or is `universalProfileAddress` itself.
   */
  modifier controlsUniversalProfile(address universalProfileAddress, address daoAddress) {
    if (msg.sender != universalProfileAddress) {
      uint256 arrayLength = participation._getControllersArrayLength(universalProfileAddress, daoAddress);
      bool addressFound = false;
      for (uint128 i = 0; i < arrayLength; i++) {
        address controllerAddress = participation._getControllerByIndex(universalProfileAddress, daoAddress, i);
        if (msg.sender == controllerAddress) {
          addressFound = true;
        }
      }
      require(
        addressFound,
        "The caller is not a controller of the Universal Profile."
      );
    }
    _;
  }

}