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
   *
   * @param _title Title of the proposal. Used to create the proposal signature.
   * @param _metadataLink Link to the metadata JSON file.
   * @param _votingDelay Period before voting can start. Must be >= with the minimum voting delay set in dao settings.
   * @param _votingPeriod Period one could execute the proposal. Must be >= with the minimum voting period set in dao settings.
   * @param _payloads An array of payloads which will be executed if the proposal is successful.
   * @param _choices Number of choices allowed for the proposal. Choice name and description must be stored inside `_metadataLink`.
   * @param _choicesPerVote Maximum number of choices allowed for each voter.
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
  ) external;

  /**
   * @notice Get the hash needed to be signed by the proposal voters.
   */
  function getProposalHash(
    address _signer,
    bytes10 _proposalSignature,
    bytes32 _choicesBitArray
  ) external view returns(bytes32 _hash);

  /**
   * @notice Execute the proposal by signature.
   */
  function executeProposal(
    bytes10 proposalSignature,
    bytes[] calldata _signatures,
    address[] calldata _signers,
    bytes32[] calldata _choicesBitArray
  ) external returns(uint256[] memory);

}