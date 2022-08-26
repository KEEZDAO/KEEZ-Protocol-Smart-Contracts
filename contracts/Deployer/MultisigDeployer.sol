// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;

// setData(bytes32[],bytes[]) & getData(bytes32[])
import {IDeployer} from "./IDeployer.sol";

// getData(bytes32)
import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

// Multisig contract
import {MultisigKeyManager} from "../Multisig/MultisigKeyManager.sol";

// LSP6Constants
import {
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY,
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX,
  _LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX
} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Constants.sol";

// Multisig Constants
import {
  _MULTISIG_QUORUM_KEY,

  _MULTISIG_PARTICIPANTS_ARRAY_KEY,
  _MULTISIG_PARTICIPANTS_ARRAY_PREFIX,
  _MULTISIG_PARTICIPANTS_MAPPING_PREFIX,
  _LSP6KEY_ADDRESSPERMISSIONS_MULTISIGPERMISSIONS_PREFIX
} from "../Multisig/MultisigConstants.sol";

// Interface
import {IMultisigDeployer} from "./IMultisigDeployer.sol";

contract MultisigDeployer is IMultisigDeployer {

  /**
   * @inheritdoc IMultisigDeployer
   */
  function deployMultisig(
    address payable _UNIVERSAL_PROFILE,
    address _KEY_MANAGER,
    address _caller,

    bytes32 _quorum,
    address[] memory _multisigParticipants,
    bytes32[] memory _multisigParticipantsPermissions
  )
    external
    returns(address _MULTISIG)
  {
    _MULTISIG = address(
      new MultisigKeyManager(
        _UNIVERSAL_PROFILE,
        _KEY_MANAGER
      )
    );
    emit MultisigDeployed(_MULTISIG);
    setMultisigPermissions(
      _UNIVERSAL_PROFILE,
      _MULTISIG,
      _caller
    );
    setMultisigSettings(
      _caller,
      _quorum,
      _multisigParticipants,
      _multisigParticipantsPermissions
    );
  }

  /**
   * @dev Update the permissions of the Universal Profile that controls the Multisig.
   */
  function setMultisigPermissions(
    address _UNIVERSAL_PROFILE,
    address _multisigAddress,
    address _caller
  )
    internal
  {
    bytes32[] memory keys = new bytes32[](3);
    bytes[] memory values = new bytes[](3);

    bytes memory encodedArrayLength = IERC725Y(_UNIVERSAL_PROFILE).getData(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY);
    uint256 oldArraylength = uint256(bytes32(encodedArrayLength));
    uint256 newArrayLength = oldArraylength + 1;

    keys[0] = _LSP6KEY_ADDRESSPERMISSIONS_ARRAY;
    values[0] = bytes.concat(bytes32(newArrayLength));

    keys[1] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(uint128(oldArraylength))));
    values[1] = bytes.concat(bytes20(_multisigAddress));

    keys[2] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_PERMISSIONS_PREFIX, bytes20(_multisigAddress)));
    values[2] = bytes.concat(bytes32(0x0000000000000000000000000000000000000000000000000000000000007fbf));

    IDeployer(msg.sender).setData(_caller, keys, values);
  }

  /**
   * @dev Set Multisig settings.
   */
  function setMultisigSettings(
    address _caller,
    bytes32 _quorum,
    address[] memory _multisigParticipants,
    bytes32[] memory _multisigParticipantsPermissions
  )
    internal
  {
    require(
      _multisigParticipantsPermissions.length == _multisigParticipantsPermissions.length
    );

    bytes32[] memory keys = new bytes32[](2 + (_multisigParticipants.length * 3));
    bytes[] memory values = new bytes[](2 + (_multisigParticipants.length * 3));

    // Multisig settings

    keys[0] = _MULTISIG_QUORUM_KEY;
    values[0] = bytes.concat(_quorum);

    // Setting Multisig Participants and their Permissions
    keys[1] = _MULTISIG_PARTICIPANTS_ARRAY_KEY;
    values[1] = bytes.concat(bytes32(_multisigParticipants.length));

    uint256 participantsLength = _multisigParticipants.length;
    for (uint128 i = 0; i < participantsLength;) {
      keys[2 + i] = bytes32(bytes.concat(_MULTISIG_PARTICIPANTS_ARRAY_PREFIX, bytes16(i)));
      values[2 + i] = bytes.concat(bytes20(_multisigParticipants[i]));

      keys[2 + _multisigParticipants.length + i] = bytes32(bytes.concat(_MULTISIG_PARTICIPANTS_MAPPING_PREFIX, bytes20(_multisigParticipants[i])));
      values[2 + _multisigParticipants.length + i] = bytes.concat(bytes32(uint256(i)));

      keys[2 + (_multisigParticipants.length * 2) + i] = bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_MULTISIGPERMISSIONS_PREFIX, bytes20(_multisigParticipants[i])));
      values[2 + (_multisigParticipants.length * 2) + i] = bytes.concat(_multisigParticipantsPermissions[i]);
    
      unchecked { ++i; }
    }

    IDeployer(msg.sender).setData(_caller, keys, values);
  }

}