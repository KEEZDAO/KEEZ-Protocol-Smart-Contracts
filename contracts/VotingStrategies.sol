// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";
import "./Interfaces/DaoAccountMetadataInterface.sol";
import "./Interfaces/DaoProposalsInterface.sol";

/**
 *
* @notice This smart contract is responsible for the voting strategies for DAO.
 *
 * @author B00ste
 * @title VotingStrategies
 * @custom:version 0.9
 */
contract VotingStrategies {

  /**
   * @notice Instance of the Proposals contract.
   */
  DaoProposalsInterface private proposals;

  /**
   * @notice Instance of the Proposals contract.
   */
  DaoAccountMetadataInterface private metadata;

  constructor(address daoAddress) {
    proposals = DaoProposalsInterface(daoAddress);
    metadata = DaoAccountMetadataInterface(daoAddress);
  }

  function _getProposalVotes(bytes32 proposalSignature)
    public
    view
    returns(uint256, uint256, uint256)
  {
    (
      string memory title,
      string memory description,
      uint256 creationTimestamp,
      uint256 votingTimestamp,
      uint256 endTimestamp,
      uint256 againstVotes,
      uint256 proVotes,
      uint256 abstainVotes
    ) = proposals._getProposalData(proposalSignature);
    delete(title);
    delete(description);
    delete(creationTimestamp);
    delete(votingTimestamp);
    delete(endTimestamp);
    return(againstVotes, proVotes, abstainVotes);
  }

  function _strategyOneResult(bytes32 proposalSignature) public view returns(bool result) {
    (
      uint256 againstVotes,
      uint256 proVotes,
      uint256 abstainVotes
    ) = _getProposalVotes(proposalSignature);

    uint256 totalActiveVotes = againstVotes + proVotes;
    uint256 totalVotes = totalActiveVotes + abstainVotes;

    if (
      proVotes/totalActiveVotes > metadata._getDaoQuorum()/totalActiveVotes &&
      totalActiveVotes/totalVotes > metadata._getDaoParticipationRate()/totalVotes
    ) {
      return true;
    }
    else {
      return false;
    }
  }

}