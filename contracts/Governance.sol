// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import "./Proposal.sol";

contract Governance {

  using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;
  
  DoubleEndedQueue.Bytes32Deque queue;

  modifier maxLenght() {
    require(
      queue.length() <= 8,
      "Maximum amout of active proposals reached."
    );
    _;
  }

  function queueProposal(
    string memory _title,
    string memory _description,
    uint256 _percentageOfVotesToPass,
    uint256 _percentaceOfForVotesToPass,
    address[] memory _targets,
    bytes[] memory _datas,
    uint256 _timeBetweenPhase0and1,
    uint256 _timeBetweenPhase1and2,
    address _tokenAddress
  ) public returns(address) {
    Proposal newProposal = new Proposal(
      _title,
      _description,
      _percentageOfVotesToPass,
      _percentaceOfForVotesToPass,
      _targets,
      _datas,
      _timeBetweenPhase0and1,
      _timeBetweenPhase1and2,
      _tokenAddress
    );
    queue.pushBack(bytes32(uint256(uint160(address(newProposal)))));
    //Proposal b = Proposal(address(uint160(uint256(queue.front()))));
    return (address(newProposal));
  }

}