// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import {
  _LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX,
  _LSP6KEY_ADDRESSPERMISSIONS_DAOPERMISSIONS_PREFIX,
  _PERMISSION_VOTE,
  _PERMISSION_RECIEVEDELEGATE,
  _KEY_DELEGATEVOTE,
  _KEY_PARTICIPANT_VOTE,
  _KEY_ADDRESSDELEGATES_ARRAY_PREFIX
} from "./DaoConstants.sol";

contract ProposalStrategies {

  function getProposalVotes(
    bytes10 proposalSignature,
    address payable UNIVERSAL_PROFILE,
    uint128 totalUsers,
    uint8 nrOfChoices
  )
    external
    view
    returns(uint256[] memory votesByChoiceIndex)
  {

    votesByChoiceIndex = new uint256[](nrOfChoices);

    for (uint128 i = 0; i < totalUsers; i++) {
      address user = address(bytes20(IERC725Y(UNIVERSAL_PROFILE).getData(
        bytes32(bytes.concat(_LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX, bytes16(i)))
      )));
      bytes32 permissions = _getPermissions(UNIVERSAL_PROFILE, user);
      if (permissions & _PERMISSION_VOTE != 0) {
        bytes2 choices;
        uint256 votes;
        bytes20 delegatedTo = bytes20(IERC725Y(UNIVERSAL_PROFILE).getData(
          bytes32(bytes.concat(_KEY_DELEGATEVOTE, bytes20(user)))
        ));

        if (delegatedTo == bytes20(0)) {
          votes = 1;
          choices = bytes2(IERC725Y(UNIVERSAL_PROFILE).getData(
            _KEY_PARTICIPANT_VOTE(proposalSignature, user)
          ));
        }
        else {
          votes = 0;
        }

        if (permissions & _PERMISSION_RECIEVEDELEGATE != 0) {
          votes += uint256(bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(
            bytes32(bytes.concat(_KEY_ADDRESSDELEGATES_ARRAY_PREFIX, bytes20(user)))
          )));
        }

        for(uint8 j = 0; j < nrOfChoices; j++) {
          choices & bytes2(uint16(1 << j)) != 0 ? votesByChoiceIndex[j] += votes : 0;
        }
      }
    }

  }

  /**
   * @dev
   */
  function _getPermissions(
    address payable UNIVERSAL_PROFILE,
    address _from
  )
    internal
    view
    returns(bytes32 permissions)
  {
    permissions = bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(
      _LSP6KEY_ADDRESSPERMISSIONS_DAOPERMISSIONS_PREFIX,
      bytes20(_from)
    ))));
  }

}