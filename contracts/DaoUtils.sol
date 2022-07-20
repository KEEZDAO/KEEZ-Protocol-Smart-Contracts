// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

/**
 * @author B00ste
 * @title DaoUtils
 * @custom:version 0.91
 */
contract DaoUtils {

  // --- MODIFIERS

  /**
   * @notice Verify if an address is a controller address.
   */
  modifier isControllerAddress(address universalProfileAddress) {
    IERC725Y UP = IERC725Y(universalProfileAddress);
    bytes32 controllersArraykey = bytes32(0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3);
    bytes memory controllersArray = UP.getData(controllersArraykey);
    bool verifyControllerAddress = false;
    for (uint128 i = 0; i < uint256(bytes32(controllersArray)); i++) {
      bytes32 addressKey = bytes32(bytes.concat(
        _bytes32ToTwoHalfs(controllersArraykey)[0],
        bytes16(i)
      ));
      if (bytes20(msg.sender) == bytes20(UP.getData(addressKey))) {
        verifyControllerAddress = true;
      }
    }
    require(
      verifyControllerAddress,
      "The message sender is not a controller address."
    );
    _;
  }

  // --- GENERAL METHODS

  /**
   * @notice Split a bytes32 in half into two bytes16 values.
   */
  function _bytes32ToTwoHalfs(bytes32 source) public pure returns(bytes16[2] memory y) {
    y = [bytes16(0), 0];
    assembly {
        mstore(y, source)
        mstore(add(y, 16), source)
    }
  }

  /**
   * @notice Add allowance for a controller address to act on behalf of the Universal Profile in DAO.
   */
  function addDaoParticipantPermission(address universalProfileAddress)
    public
    isControllerAddress(universalProfileAddress)
  {

    require(!verifyAddress(universalProfileAddress), "Address already has this permission.");

    IERC725Y UP = IERC725Y(universalProfileAddress);

    bytes32 key = bytes32(bytes.concat(
      bytes6(keccak256("AddressPermissions")),
      bytes4(keccak256("Permissions")),
      bytes2(0),
      bytes20(msg.sender)
    ));
    UP.setData(
      key,
      bytes.concat(
        bytes32(uint256(bytes32(UP.getData(key))) + uint256(1 << 15))
      )
    );

  }

  /**
   * @notice Remove allowance for a controller address to act on behalf of the Universal Profile in DAO.
   */
  function removeDaoParticipantPermission(address universalProfileAddress)
    public
  {
    
    require(verifyAddress(universalProfileAddress), "Address doesen't have this permission.");

    IERC725Y UP = IERC725Y(universalProfileAddress);

    bytes32 key = bytes32(bytes.concat(
      bytes6(keccak256("AddressPermissions")),
      bytes4(keccak256("Permissions")),
      bytes2(0),
      bytes20(msg.sender)
    ));
    UP.setData(
      key,
      bytes.concat(
        bytes32(uint256(bytes32(UP.getData(key))) - uint256(1 << 15))
      )
    );

  }

  /**
   * @notice Verify if the address has allowance to act on behalf of the Universal Profile in DAO.
   */
  function verifyAddress(address universalProfileAddress) public view returns(bool) {
    IERC725Y UP = IERC725Y(universalProfileAddress);
    bytes32 key = bytes32(bytes.concat(
        bytes6(keccak256("AddressPermissions")),
        bytes4(keccak256("Permissions")),
        bytes2(0),
        bytes20(msg.sender)
    ));
    bytes memory upPermissions = UP.getData(key);

    if(uint256(bytes32(upPermissions)) & (1 << 15) != 0) {
      return true;
    }
    else {
      return false;
    }

  }

}