// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;

interface IUniversalProfileDeployer {

  /**
   * @notice Deploy a Universal Profile and a Key Manager
   */
  function deployUniversalProfile(
    address _unviersalReceiverDelegateUPAddress,
    bytes memory _universalProfileMetadata
  ) external returns(address payable _UNIVERSAL_PROFILE, address _KEY_MANAGER);

}