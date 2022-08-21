// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;

interface IMultisigDeployer {

  /**
   * @notice Emit this whenever a new Multisig is created.
   * @param _MULTISIG Address of the Multisg.
   */
  event NewMultisigCreated(address _MULTISIG);

  /**
   * @notice Deploy a new Multisig.
   * @param _UNIVERSAL_PROFILE The address of the Universal Profile of the DAO.
   * @param _KEY_MANAGER Address of the Key Manager of the Universal Profile.
   */
  function deployMultisig(
    address payable _UNIVERSAL_PROFILE,
    address _KEY_MANAGER,
    address _caller,

    bytes memory _JSONMultisigMetdata,
    bytes32 quorum,
    address[] memory _multisigParticipants,
    bytes32[] memory _multisigParticipantsPermissions
  ) external returns(address _MULTISIG);

}