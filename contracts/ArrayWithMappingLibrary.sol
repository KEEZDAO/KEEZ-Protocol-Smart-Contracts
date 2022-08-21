// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.10;

// Interfaces for interacting with a Universal Profile.

// getData(...)
import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
// setData(...)
import {ILSP6KeyManager} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/ILSP6KeyManager.sol";

/**
 *
 * @notice Motivation: This library would be used to create arrays of elements
 * and map the index of the elements of the array using the setData(...)
 * of a contract that implemented ERC725Y.
 * The
 *
 * @title ArrayWithMappingLibrary
 * @author B00ste
 */
library ArrayWithMappingLibrary {
    /**
     * @dev Returns `arrayLenth` + 1 if the array at `_key` doesn't contain `_value`
     * and the index of the `_value` inside the array at `_key` if it contains `_value`.
     */
    function _arrayContains(
        address payable _UNIVERSAL_PROFILE,
        bytes12 arrayElementMapPrefix,
        bytes memory arrayElement
    ) internal view returns (bool, uint256) {
        bytes memory encodedElementIndex = IERC725Y(_UNIVERSAL_PROFILE).getData(
            bytes32(bytes.concat(arrayElementMapPrefix, bytes20(arrayElement)))
        );

        if (encodedElementIndex.length == 0) {
            return (false, 0);
        } else {
            return (true, uint256(bytes32(encodedElementIndex)));
        }
    }

    /**
     * @dev Add an element to the array at `_key` if it is non-existent yet.
     */
    function _addElement(
        address payable _UNIVERSAL_PROFILE,
        address _KEY_MANAGER,
        bytes32 arrayLengthKey,
        bytes16 arrayIndexPerfix,
        bytes12 arrayElementMapPrefix,
        bytes memory arrayElement
    ) internal returns (bool) {
        uint256 oldArrayLength = uint256(
            bytes32(IERC725Y(_UNIVERSAL_PROFILE).getData(arrayLengthKey))
        );
        uint256 newArrayLength = oldArrayLength + 1;
        (bool response, uint256 elementIndex) = _arrayContains(
            _UNIVERSAL_PROFILE,
            arrayElementMapPrefix,
            arrayElement
        );
        delete elementIndex;
        if (response) return false;

        bytes32[] memory keys = new bytes32[](3);
        bytes[] memory values = new bytes[](3);

        keys[0] = arrayLengthKey;
        values[0] = bytes.concat(bytes32(newArrayLength));

        keys[1] = bytes32(
            bytes.concat(arrayIndexPerfix, bytes16(uint128(oldArrayLength)))
        );
        values[1] = arrayElement;

        keys[2] = bytes32(
            bytes.concat(arrayElementMapPrefix, bytes20(arrayElement))
        );
        values[2] = bytes.concat(bytes32(oldArrayLength));

        ILSP6KeyManager(_KEY_MANAGER).execute(
            abi.encodeWithSelector(
                bytes4(keccak256("setData(bytes32[],bytes[])")),
                keys,
                values
            )
        );
        return true;
    }

    /**
     * @dev Remove an array element if it exists in the array at `_key`.
     * implementation borrowed from Yamen, swap and pop.
     */
    function _removeElement(
        address payable _UNIVERSAL_PROFILE,
        address _KEY_MANAGER,
        bytes32 arrayLengthKey,
        bytes16 arrayIndexPerfix,
        bytes12 arrayElementMapPrefix,
        bytes memory arrayElement
    ) internal returns (bool) {
        uint256 oldArrayLength = uint256(
            bytes32(IERC725Y(_UNIVERSAL_PROFILE).getData(arrayLengthKey))
        );
        uint256 newArrayLength = oldArrayLength - 1;
        (bool response, uint256 elementIndex) = _arrayContains(
            _UNIVERSAL_PROFILE,
            arrayElementMapPrefix,
            arrayElement
        );
        if (!response) return false;

        bytes memory encodedArrayLastElement = IERC725Y(_UNIVERSAL_PROFILE)
            .getData(
                bytes32(
                    bytes.concat(
                        arrayIndexPerfix,
                        bytes16(uint128(newArrayLength))
                    )
                )
            );

        bytes32[] memory keys = new bytes32[](5);
        bytes[] memory values = new bytes[](5);

        keys[0] = arrayLengthKey;
        values[0] = bytes.concat(bytes32(newArrayLength));

        keys[1] = bytes32(
            bytes.concat(arrayIndexPerfix, bytes16(uint128(elementIndex)))
        );
        values[1] = encodedArrayLastElement;

        keys[2] = bytes32(
            bytes.concat(arrayIndexPerfix, bytes16(uint128(newArrayLength)))
        );
        values[2] = "";

        keys[3] = bytes32(
            bytes.concat(
                arrayElementMapPrefix,
                bytes20(encodedArrayLastElement)
            )
        );
        values[3] = bytes.concat(bytes32(elementIndex));

        keys[4] = bytes32(
            bytes.concat(arrayElementMapPrefix, bytes20(arrayElement))
        );
        values[4] = "";

        ILSP6KeyManager(_KEY_MANAGER).execute(
            abi.encodeWithSelector(
                bytes4(keccak256("setData(bytes32[],bytes[])")),
                keys,
                values
            )
        );
        return true;
    }
}
