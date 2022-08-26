// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;

interface IDaoDeployer {

  /**
   * @notice Emit this event whenever a new DAO is created.
   * @param _DAO_PERMISSIONS Address of the DAO Permsissions contract.
   * @param _DAO_DELEGATES Address of the DAO Delegates contract.
   * @param _DAO_PROPOSALS Address of the DAO Proposals contract.
   */
  event DaoDeployed(address _DAO_PERMISSIONS, address _DAO_DELEGATES, address _DAO_PROPOSALS);

  /**
   * @notice Deploy a new Dao.
   * @param _UNIVERSAL_PROFILE The address of the Universal Profile of the DAO.
   * @param _KEY_MANAGER Address of the Key Manager of the Universal Profile.
   */
  function deployDao(
    address payable _UNIVERSAL_PROFILE,
    address _KEY_MANAGER,
    address _caller,

    bytes32 _majority,
    bytes32 _participationRate,
    bytes32 _minimumVotingDelay,
    bytes32 _minimumVotingPeriod,
    bytes32 _minimumExecutionDelay,
    address[] memory _daoParticipants,
    bytes32[] memory _daoParticipantsPermissions
  ) external returns(address[] memory _DAO_ADDRESSES);

}