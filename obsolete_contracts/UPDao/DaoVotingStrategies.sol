// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./LSP0ERC725Account.sol";
import "./Interfaces/DaoAccountMetadataInterface.sol";
import "./Interfaces/DaoProposalsInterface.sol";

/**
 *
* @notice This smart contract is responsible for the voting strategies for DAO.
 *
 * @author B00ste
 * @title DaoVotingStrategies
 * @custom:version 0.92
 */
contract DaoVotingStrategies {

  /**
   * @notice Instance of the DAO key manager.
   */
  LSP0ERC725Account private DAO;

  /**
   * @notice Instance of the Proposals contract.
   */
  DaoProposalsInterface private proposals;

  /**
   * @notice Instance of the Proposals contract.
   */
  DaoAccountMetadataInterface private metadata;

  /**
   * @notice Initializing the contract.
   */
  bool private initialized = false;
  function init(LSP0ERC725Account _DAO, address daoAddress) external{
    require(!initialized, "The contract is already initialized.");
    DAO = _DAO;
    proposals = DaoProposalsInterface(daoAddress);
    metadata = DaoAccountMetadataInterface(daoAddress);
    initialized = true;
  }

  function _getProposalVotes(bytes10 proposalSignature)
    public
    view
    returns(uint256 againstVotes, uint256 proVotes, uint256 abstainVotes)
  {
    againstVotes = uint256(bytes32(proposals._getAttributeValue(proposalSignature, bytes20(keccak256("AgainstVotes")))));
    proVotes = uint256(bytes32(proposals._getAttributeValue(proposalSignature, bytes20(keccak256("ProVotes")))));
    abstainVotes = uint256(bytes32(DAO.getData(bytes32(keccak256("DAOPermissionsAddresses[]")))));
  }

  function _strategyOneResult(bytes10 proposalSignature) public view returns(bool result) {
    (
      uint256 againstVotes,
      uint256 proVotes,
      uint256 abstainVotes
    ) = _getProposalVotes(proposalSignature);

    abstainVotes -= (againstVotes + proVotes);
    uint256 totalActiveVotes = againstVotes + proVotes;
    uint256 totalVotes = totalActiveVotes + abstainVotes;

    if (
      proVotes/totalActiveVotes > metadata._getDaoMajority()/totalActiveVotes &&
      totalActiveVotes/totalVotes > metadata._getDaoParticipationRate()/totalVotes
    ) {
      return true;
    }
    else {
      return false;
    }
  }

}