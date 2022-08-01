// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// Interfaces for interacting with a Universal Profile.

// getData(...)
import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
// setData(...)
import {ILSP6KeyManager} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/ILSP6KeyManager.sol";

// LSP6 Constants
import {
  setDataSingleSelector,
  setDataMultipleSelector
} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Constants.sol";

library ERC725ArrayUtilsLibrary {

  /**
   * @dev Struct used to store the `IERC725Y` `ILSP6KeyManager` addresses.
   */
  struct Targets {
    address payable UNIVERSAL_PROFILE;
    address KEY_MANAGER;
  }

  function ADD_TARGETS(
    Targets storage targets,
    address payable _UNIVERSAL_PROFILE,
    address _KEY_MANAGER
  ) internal returns(bool) {
    if (
      targets.UNIVERSAL_PROFILE == address(0) &&
      targets.KEY_MANAGER == address(0)
    ) {
      targets.UNIVERSAL_PROFILE = _UNIVERSAL_PROFILE;
      targets.KEY_MANAGER = _KEY_MANAGER;
      return true;
    }
    else return false;
  }

  /**
   * @dev Returns `arrayLenth` + 1 if the array at `_key` doesn't contain `_value`
   * and the index of the `_value` inside the array at `_key` if it contains `_value`.
   */
  function ARRAY_CONTAINS(
    Targets storage targets,
    bytes32 _key,
    bytes memory _value
  ) internal view returns(uint256 index) {
    uint256 arrayLength = uint256(bytes32(IERC725Y(targets.UNIVERSAL_PROFILE).getData(_key)));
    index = arrayLength + 1;
    for (uint128 i = 0; i < arrayLength; i++) {
      bytes memory value = IERC725Y(targets.UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(
        bytes16(_key),
        bytes16(i)
      )));

      if (_value.length == value.length) {
        for (uint128 j = 0; value[j] == _value[j]; i++) {
          if (j == _value.length - 1) index = uint256(i);
        }
      }
    }
  }

  /**
   * @dev Add an element to the array at `_key` if it is non-existent yet.
   */
  function ARRAY_ADD(
    Targets storage targets,
    bytes32 _key,
    bytes memory _value
  ) internal returns(bool) {
    uint256 arrayLength = uint256(bytes32(IERC725Y(targets.UNIVERSAL_PROFILE).getData(_key)));
    if (ARRAY_CONTAINS(targets,_key,_value) != arrayLength + 1) return false;

    bytes32[] memory keys = new bytes32[](2);
    bytes[] memory values = new bytes[](2);

    keys[0] = _key;
    values[0] = bytes.concat(bytes32(arrayLength + 1));

    keys[1] = bytes32(bytes.concat(
      bytes16(_key),
      bytes16(uint128(arrayLength))
    ));
    values[1] = _value;

    ILSP6KeyManager(targets.KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataMultipleSelector,
        keys, values
      )
    );
    return true;
  }

  /**
   * @dev Remove an array element if it exists in the array at `_key`.
   */
  function ARRAY_REMOVE(
    Targets storage targets,
    bytes32 _key,
    bytes memory _value
  ) internal returns(bool) {
    uint256 arrayLength = uint256(bytes32(IERC725Y(targets.UNIVERSAL_PROFILE).getData(_key)));
    uint256 valueIndex = ARRAY_CONTAINS(targets,_key,_value);
    if (valueIndex == arrayLength + 1) return false;

    bytes32[] memory keys = new bytes32[](arrayLength - valueIndex);
    bytes[] memory values = new bytes[](arrayLength - valueIndex);

    for (uint256 i = valueIndex; i < arrayLength; i++) {
      keys[i] = bytes32(bytes.concat(
        bytes16(_key),
        bytes16(uint128(i))
      ));
      values[i] = bytes.concat(IERC725Y(targets.UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(
        bytes16(_key),
        bytes16(uint128(i + 1))
      ))));
    }

    ILSP6KeyManager(targets.KEY_MANAGER).execute(
      abi.encodeWithSelector(
        setDataMultipleSelector,
        keys, values
      )
    );
    return true;
  }

}