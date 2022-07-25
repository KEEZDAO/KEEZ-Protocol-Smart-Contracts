// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./LSP0ERC725Account.sol";
import "./LSP6KeyManager.sol";
import "./Interfaces/DaoPermissionsInterface.sol";
import "./Utils/AccessControl.sol";
import "./Utils/DaoUtils.sol";

/**
 *
* @notice This smart contract is responsible for the metadata of a Universal Profile DAO. 
 *
 * @author B00ste
 * @title DaoAccountMetadata
 * @custom:version 0.92
 */
contract DaoAccountMetadata is AccessControl {

  /**
   * @notice Instance of the DAO key manager.
   */
  LSP0ERC725Account private DAO;

  /**
   * @notice Initialize the Key Manager of the DAO.
   */
  LSP6KeyManager private KEY_MANAGER;

  /**
   * @notice Initializing the contract.
   */
  function init(LSP0ERC725Account _DAO, LSP6KeyManager _KEY_MANAGER, DaoUtils _utils, address daoAddress) external isNotInitialized() {
    require(!initialized, "The contract is already initialized.");
    DAO = _DAO;
    KEY_MANAGER = _KEY_MANAGER;
    initAccessControl(_utils, daoAddress);
    initialized = true;
  }

  // --- ATTRIBUTES

  /**
   * @notice Key for the name of the DAO.
   */
  bytes32 private nameKey = 0x55e49609591f684ecf6f2909c9e20c2439b990887b9c3fe108b154c9077d85cf;

  /**
   * @notice Key for the description of the DAO.
   */
  bytes32 private descriptionKey = 0x95e794640ff3efd16bfe738f1a9bf2886d166af549121f57d6e14af6b513f45d;

  /**
   * @notice key for the percentage of pro votes needed for a proposal to pass.
   */
  bytes32 private majorityKey = 0x1c990d1606629a2681dbc22754450a119d5896cd739732a966bd0a2e08647359;

  /**
   * @notice key for participation rate needed to be reached for a proposal to be valid.
   */
  bytes32 private participationRateKey = 0xf89f507ecd9cb7646ce1514ec6ab90d695dac9314c3771f451fd90148a3335a9;

  /**
   * @notice key for the time requiered to pass before ending the queueing period is possible.
   */
  bytes32 private votingDelayKey = 0x5bd05fa174be6a4aa4a8222f8837a27a381de14e7797cf7945df58b0626e6c3d;

  /**
   * @notice key for the time requiered to pass before ending the voting period is possible.
   */
  bytes32 private votingPeriodKey = 0xd08ca3a83d59467dd8ba57e940549874ea8310a1ebfb4396959235b00035d777;

  // --- GETTERS & SETTERS

  /**
   * @notice Get the name of the DAO.
   */
  function _getDaoName() external view returns(string memory name) {
    name = string(DAO.getData(nameKey));
  }

  /**
   * @notice Set the name of the DAO.
   */
  function _setDaoName(string memory name) external isDao(msg.sender) isInitialized() {
    KEY_MANAGER.execute(abi.encodeWithSignature("setData(bytes32,bytes)", nameKey, bytes(name)));
  }

  /**
   * @notice Get the description of the DAO.
   */
  function _getDaoDescription() external view returns(string memory description) {
    description = string(DAO.getData(descriptionKey));
  }

  /**
   * @notice Set the description of the DAO.
   */
  function _setDaoDescription(string memory description) external isDao(msg.sender) isInitialized() {
    KEY_MANAGER.execute(abi.encodeWithSignature("setData(bytes32,bytes)", descriptionKey, bytes(description)));
  }

  /**
   * @notice Get the majority of the DAO.
   */
  function _getDaoMajority() external view returns(uint8 majority) {
    majority = uint8(bytes1(DAO.getData(majorityKey)));
  }

  /**
   * @notice Set the majority of the DAO.
   */
  function _setDaoMajority(uint8 majority) external isDao(msg.sender) isInitialized() {
    KEY_MANAGER.execute(abi.encodeWithSignature("setData(bytes32,bytes)", majorityKey, bytes.concat(bytes1(majority))));
  }

  /**
   * @notice Get the participation rate of the DAO.
   */
  function _getDaoParticipationRate() external view returns(uint8 participationRate) {
    participationRate = uint8(bytes1(DAO.getData(participationRateKey)));
  }

  /**
   * @notice Set the participation rate of the DAO.
   */
  function _setDaoParticipationRate(uint8 participationRate) external isDao(msg.sender) isInitialized() {
    KEY_MANAGER.execute(abi.encodeWithSignature("setData(bytes32,bytes)", participationRateKey, bytes.concat(bytes1(participationRate))));
  }

  /**
   * @notice Get the voting delay of the DAO.
   */
  function _getDaoVotingDelay() external view returns(uint256 votingDelay) {
    votingDelay = uint256(bytes32(DAO.getData(votingDelayKey)));
  }

  /**
   * @notice Set the voting delay of the DAO.
   */
  function _setDaoVotingDelay(uint256 votingDelay) external isDao(msg.sender) isInitialized() {
    KEY_MANAGER.execute(abi.encodeWithSignature("setData(bytes32,bytes)", votingDelayKey, bytes.concat(bytes32(votingDelay))));
  }

  /**
   * @notice Get the voting period of the DAO.
   */
  function _getDaoVotingPeriod() external view returns(uint256 votingPeriod) {
    votingPeriod = uint256(bytes32(DAO.getData(votingPeriodKey)));
  }

  /**
   * @notice Set the voting period of the DAO.
   */
  function _setDaoVotingPeriod(uint256 votingPeriod) external isDao(msg.sender) isInitialized() {
    KEY_MANAGER.execute(abi.encodeWithSignature("setData(bytes32,bytes)", votingPeriodKey, bytes.concat(bytes32(votingPeriod))));
  }

}