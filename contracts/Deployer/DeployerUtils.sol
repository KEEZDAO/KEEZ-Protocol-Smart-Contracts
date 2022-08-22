// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;

library DeployerUtils {

  function encodeDaoData(
    bytes memory _JSONDaoMetdata,
    bytes32 _majority,
    bytes32 _participationRate,
    bytes32 _minimumVotingDelay,
    bytes32 _minimumVotingPeriod,
    bytes32 _minimumExecutionDelay,
    address[] memory _daoParticipants,
    bytes32[] memory _daoParticipantsPermissions
  )
    external
    pure
    returns (bytes memory encodedData)
  {
    encodedData = bytes.concat(
      _majority,
      _participationRate,
      _minimumVotingDelay,
      _minimumVotingPeriod,
      _minimumExecutionDelay,
      bytes32(_daoParticipants.length)
    );
    for (uint256 i = 0; i < _daoParticipants.length; i++) {
      encodedData = bytes.concat(
        encodedData,
        bytes12(0),
        bytes20(_daoParticipants[i]),
        _daoParticipantsPermissions[i]
      );
    }
    encodedData = bytes.concat(
      encodedData,
      _JSONDaoMetdata
    );
  }

  function encodeMultisigData(

  )
    external
  {
    
  }

}