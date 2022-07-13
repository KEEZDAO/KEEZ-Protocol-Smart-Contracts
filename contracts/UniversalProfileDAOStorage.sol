// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import "@lukso/lsp-smart-contracts/contracts/LSP0ERC725Account/LSP0ERC725Account.sol";

/**
 * @author B00ste
 * @title UniversalProfileDAOStorage
 */
contract UniversalProfileDAOStorage {

  /**
   * @notice Instance of the DAO key manager.
   */
  LSP0ERC725Account DAO = new LSP0ERC725Account(address(this));

  /**
   * @notice Permissions.
   * VOTE    = 0x0000000000000000000000000000000000000000000000000000000000000001; // 0001
   * PROPOSE = 0x0000000000000000000000000000000000000000000000000000000000000002; // 0010
   * EXECUTE = 0x0000000000000000000000000000000000000000000000000000000000000004; // 0100
   */
  bytes32[3] private permissions = [
    bytes32(0x0000000000000000000000000000000000000000000000000000000000000001),
    0x0000000000000000000000000000000000000000000000000000000000000002,
    0x0000000000000000000000000000000000000000000000000000000000000004
  ];

  /**
   * @notice The key for the length of the array of aaddresses that have permissions in the DAO.
   */
  bytes32 private daoAddressesArrayKey = bytes32(keccak256("DAOPermissionsAddresses[]"));

  /**
   * @notice The key for the length of the array of DAO proposals.
   */
  bytes32 private daoProposalsArrayKey = bytes32(keccak256("ProposalsArray[]"));

  // --- INTERNAL METHODS

  /**
   * @notice Split a bytes32 in half into two bytes16 values.
   */
  function _bytes32ToTwoHalfs(bytes32 source) internal pure returns(bytes16[2] memory y) {
    y = [bytes16(0), 0];
    assembly {
        mstore(y, source)
        mstore(add(y, 16), source)
    }
  }

  // --- GETTERS & SETTERS

  /**
   * @notice Get the length of the array of the addresses that have permissions in the DAO.
   */
  function _getDaoAddressesArrayLength() internal view returns(uint256 length) {
    length = uint256(bytes32(DAO.getData(daoAddressesArrayKey)));
  }

  /**
   * @notice Set the length of the array of the addresses that have permissions in the DAO.
   *
   * @param length the length of the array of addresses that are participants to the DAO.
   */
  function _setDaoAddressesArrayLength(uint256 length) internal returns(bytes memory newLength) {
    newLength = bytes.concat(bytes32(length));
    DAO.setData(daoProposalsArrayKey, newLength);
  }

  /**
   * @notice Get an address of a DAO perticipant by index.
   *
   * @param index The index of the an address.
   */
  function _getDaoAddressByIndex(uint256 index) internal view returns(bytes32 daoAddressKey, bytes memory daoAddress) {
    bytes16[2] memory daoAddressesArrayKeyHalfs = _bytes32ToTwoHalfs(daoAddressesArrayKey);
    daoAddressKey = bytes32(bytes.concat(
      daoAddressesArrayKeyHalfs[0], bytes16(uint128(index))
    ));
    daoAddress = DAO.getData(daoAddressKey);
  }

  /**
   * @notice Set an address of a DAO perticipant at an index.
   *
   * @param index The index of an address.
   * @param _daoAddress The address of a DAO participant.
   */
  function _setDaoAddressByIndex(uint256 index, address _daoAddress) internal returns(bytes32 daoAddressKey, bytes memory daoAddress) {
    bytes16[2] memory daoAddressesArrayKeyHalfs = _bytes32ToTwoHalfs(daoAddressesArrayKey);
    daoAddressKey = bytes32(bytes.concat(
      daoAddressesArrayKeyHalfs[0], bytes16(uint128(index))
    ));
    daoAddress = bytes.concat(bytes20(_daoAddress));
    DAO.setData(daoAddressKey, daoAddress);
  }

  /**
   * @notice Get addresses DAO permmissions BitArray.
   *
   * @param daoAddress The address of a DAO participant.
   */
  function _getAddressDaoPermission(address daoAddress) internal view returns(bytes32 addressPermssionsKey, bytes memory addressPermssions) {
    addressPermssionsKey = bytes32(bytes.concat(
      bytes6(keccak256("DAOPermissionsAddresses")),
      bytes4(keccak256("DAOPermissions")),
      bytes2(0),
      bytes20(daoAddress)
    ));
    addressPermssions = DAO.getData(addressPermssionsKey);
  }

  /**
   * @notice Set addresses DAO permmissions BitArray by index.
   *
   * @param daoAddress The address of a DAO participant.
   * @param index The index of the permissions array.
   * Index 0 is the VOTE permission.
   * Index 1 is the PROPOSE permission.
   * Index 2 is the EXECUTE permission.
   */
  function _setAddressDaoPermission(address daoAddress, uint8 index, bool permissionAdded) internal returns(bytes32 addressPermssionsKey, bytes memory addressPermssions) {
    addressPermssionsKey = bytes32(bytes.concat(
      bytes6(keccak256("DAOPermissionsAddresses")),
      bytes4(keccak256("DAOPermissions")),
      bytes2(0),
      bytes20(daoAddress)
    ));
    if (permissionAdded) {
      addressPermssions = bytes.concat(
        bytes32(uint256(bytes32(DAO.getData(addressPermssionsKey))) + uint256(permissions[index]))
      );
    }
    else {
      addressPermssions = bytes.concat(
        bytes32(uint256(bytes32(DAO.getData(addressPermssionsKey))) - uint256(permissions[index]))
      );
    }
    DAO.setData(addressPermssionsKey, addressPermssions);
  }

  /**
   * @notice Get the proposals array lenngth.
   */
  function _getProposalsArrayLength() internal view returns(uint256 length) {
    length = uint256(bytes32(DAO.getData(daoProposalsArrayKey)));
  }

  /**
   * @notice Set the proposals array lenngth.
   */
  function setProposalsArrayLength(uint256 length) internal returns(bytes memory newLength) {
    newLength = bytes.concat(bytes32(length));
    DAO.setData(daoProposalsArrayKey, newLength);
  }

  /**
   * @notice Get Proposal by index.
   */
  function _getProposalByIndex(uint256 index) internal view returns(bytes32 proposalKey, bytes memory proposalSignature) {
    bytes16[2] memory daoProposalsArrayKeyHalfs = _bytes32ToTwoHalfs(daoProposalsArrayKey);
    proposalKey = bytes32(bytes.concat(
      daoProposalsArrayKeyHalfs[0], bytes16(uint128(index))
    ));
    proposalSignature = DAO.getData(proposalKey);
  }

  /**
   * @notice Set Proposal by index.
   */
  function _getProposalByIndex(uint256 index, bytes32 _proposalSignature) internal returns(bytes32 proposalKey, bytes memory proposalSignature) {
    bytes16[2] memory daoProposalsArrayKeyHalfs = _bytes32ToTwoHalfs(daoProposalsArrayKey);
    proposalKey = bytes32(bytes.concat(
      daoProposalsArrayKeyHalfs[0], bytes16(uint128(index))
    ));
    proposalSignature = bytes.concat(_proposalSignature);
    DAO.setData(proposalKey, proposalSignature);
  }

  /**
   * @notice Get DAO proposal data.
   */
  function _getProposalData(bytes32 proposalSignature) internal view returns(
      string memory title,
      string memory description,
      uint256 creationTimestamp,
      uint256 votingTimestamp,
      uint256 endTimestamp,
      uint256 againstVotes,
      uint256 proVotes,
      uint256 abstainVotes
  ) {
    (
      title,
      description,
      creationTimestamp,
      votingTimestamp,
      endTimestamp,
      againstVotes,
      proVotes,
      abstainVotes
    ) = abi.decode(DAO.getData(proposalSignature), (string, string, uint256, uint256, uint256, uint256, uint256, uint256));
  }

  /**
   * @notice Set DAO proposal data.
   */
  function _setProposalData(
      string memory title,
      string memory description,
      uint256 creationTimestamp,
      uint256 votingTimestamp,
      uint256 endTimestamp,
      uint256 againstVotes,
      uint256 proVotes,
      uint256 abstainVotes
  ) internal returns(bytes32 proposalSignature, bytes memory proposalData) {
    proposalData = abi.encode(
      title,
      description,
      creationTimestamp,
      votingTimestamp,
      endTimestamp,
      againstVotes,
      proVotes,
      abstainVotes
    );
    proposalSignature = keccak256(proposalData);
    DAO.setData(proposalSignature, proposalData);
  }


}