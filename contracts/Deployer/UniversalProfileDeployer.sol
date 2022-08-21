// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;

// setData(bytes32[],bytes[]) & getData(bytes32[])
import {IDeployer} from "./IDeployer.sol";

// LSP0ERC725Account
import {LSP0ERC725Account} from "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";

// LSP6KeyManager
import {LSP6KeyManager} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6KeyManager.sol";

// Universal Receiver Constants
import {
  _LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY
} from "@lukso/lsp-smart-contracts/contracts/LSP1UniversalReceiver/LSP1Constants.sol";

// LSP3Constants 
import {
  _LSP3_SUPPORTED_STANDARDS_KEY,
  _LSP3_SUPPORTED_STANDARDS_VALUE,
  _LSP3_PROFILE_KEY
} from "@lukso/lsp-smart-contracts/contracts/LSP3UniversalProfile/LSP3Constants.sol";

// LSP6Constants
import {
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY,
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX,
  _LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX
} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Constants.sol";

// Interface
import {IUniversalProfileDeployer} from "./IUniversalProfileDeployer.sol";

contract UniversalProfileDeployer is IUniversalProfileDeployer {

  /**
   * @inheritdoc IUniversalProfileDeployer
   */
  function deployUniversalProfile(
    address _unviersalReceiverDelegateUPAddress,
    bytes memory _universalProfileMetadata
  )
    external
    returns(address payable _UNIVERSAL_PROFILE, address _KEY_MANAGER)
  {
    _UNIVERSAL_PROFILE = payable(
      new LSP0ERC725Account(msg.sender)
    );
    _KEY_MANAGER = address(
      new LSP6KeyManager(_UNIVERSAL_PROFILE)
    );
    updateUniversalProfileData(
      _UNIVERSAL_PROFILE,
      _unviersalReceiverDelegateUPAddress,
      _universalProfileMetadata
    );
  }

  /**
   * @dev Update the Universal Profile data.
   */
  function updateUniversalProfileData(
    address payable _UNVIERSAL_PROFILE,
    address _unviersalReceiverDelegateUPAddress,
    bytes memory universalProfileMetadata
  )
    internal
  {
    bytes32[] memory keys = new bytes32[](3);
    bytes[] memory values = new bytes[](3);

    // Update the URD key
    keys[0] = _LSP1_UNIVERSAL_RECEIVER_DELEGATE_KEY;
    values[0] = bytes.concat(bytes20(_unviersalReceiverDelegateUPAddress));

    // Update UP supported standards
    keys[1] = _LSP3_SUPPORTED_STANDARDS_KEY;
    values[1] = _LSP3_SUPPORTED_STANDARDS_VALUE;

    // Update the JSON url of the Universal Profile
    keys[2] = _LSP3_PROFILE_KEY;
    values[2] = bytes(universalProfileMetadata);

    IDeployer(msg.sender).setDataOf(_UNVIERSAL_PROFILE, keys, values);
  }

}