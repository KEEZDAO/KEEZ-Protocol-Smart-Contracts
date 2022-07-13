// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

contract GetKeys {

  function bytes32ToTwoHalfs(bytes32 source) public pure returns(bytes16[2] memory y) {
    y = [bytes16(0), 0];
    assembly {
        mstore(y, source)
        mstore(add(y, 16), source)
    }
  }

  function getArrayKey() public pure returns(bytes32 a) {
    a = bytes32(keccak256("AddressDAOPermissions[]"));
  }

  function getAddressKey() public pure returns(bytes32[5] memory) {
    bytes16[2] memory b = bytes32ToTwoHalfs(getArrayKey());
    /*a = bytes32(bytes.concat(
      b[0], bytes16(0)
    ));*/
    bytes32[5] memory x;
    for(uint128 i = 0; i < 5; i++) {
      x[i] = bytes32(bytes.concat(
      b[0], bytes16(i)
    ));
    }
    return x;
  }

  function getKeys(address universalProfileAddress) public pure returns(bytes32 a) {
    a = bytes32(bytes.concat(
      bytes6(keccak256("AddressDAOPermissions")),
      bytes4(keccak256("DAOPermissions")),
      bytes2(0),
      bytes20(universalProfileAddress)
    ));
  }

}