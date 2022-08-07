// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

/**
 * @author B00ste
 * @title IDaoProposals
 * @custom:version 1
 */
interface IDaoProposals {

  /**
   * @notice This event is emited every time a proposal is created.
   *
   * @param proposalSignature The signature of the proposal that was created.
   */
  event ProposalCreated(bytes10 proposalSignature);

  /**
   * @notice Create a proposal.
   */
  function createProposal(
    string calldata _title,
    string calldata _metadataLink,
    uint48 _votingDelay,
    uint48 _votingPeriod,
    bytes[] calldata _payloads,
    uint8 _choices,
    uint8 _choicesPerVote
  ) external;

  /**
   *
   */
  function getProposalHash(
    address _signer,
    bytes10 _proposalSignature,
    bool _response
  )
    external
    view
    returns(bytes32 _hash);

  /**
   * @notice Execute the proposal by signature.
   */
  function executeProposal(bytes10 proposalSignature, bytes[] calldata _signatures, address[] calldata _signers) external;

}