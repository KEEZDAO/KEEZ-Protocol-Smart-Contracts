// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_LSP6 = 0xc403d48f;


// --- PERMISSIONS KEYS


// keccak256("AddressPermissions[]")
bytes32 constant _LSP6KEY_ADDRESSPERMISSIONS_ARRAY = 0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3;

// AddressPermissions[index]
bytes16 constant _LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX = 0xdf30dba06db6a30e65354d9a64c60986;

// AddressPermissions:...
bytes6 constant _LSP6KEY_ADDRESSPERMISSIONS_PREFIX = 0x4b80742de2bf;

// bytes6(keccak256("AddressPermissions")) + bytes4(keccak256("MultisigPermissions")) + bytes2(0)
// AddressPermissions:MultisigPermissions:<address> --> bytes32
bytes12 constant _LSP6KEY_ADDRESSPERMISSIONS_MULTISIGPERMISSIONS_PREFIX = 0x4164647265734d756c740000;

// DEFAULT PERMISSIONS VALUES
bytes32 constant _PERMISSION_VOTE             = 0x0000000000000000000000000000000000000000000000000000000000000001;
bytes32 constant _PERMISSION_PROPOSE          = 0x0000000000000000000000000000000000000000000000000000000000000002;


// --- PARTICIPATION KEYS


// keccak256("MultisigParticipants[]")
bytes32 constant _MULTISIG_PARTICIPANTS_KEY = 0x54aef89da199194b126d28036f71291726191dbff7160f9d0986952b17eaedb4;

// MultisigParticipants[index]
bytes16 constant _MULTISIG_PARTICIPANTS_KEY_PREFIX = 0x54aef89da199194b126d28036f712917;


// --- PROPOSAL KEYS


// keccak("MultisigProposal")
bytes4 constant _MULTISIG_PROPOSAL_KEY_BYTES4_PREFIX = 0x4d756c74;

// Proposal signature := _MULTISIG_PROPOSAL_KEY_PREFIX + bytes6(<Creation Timestamp>) + bytes20("<Title>")
function _MULTISIG_PROPOSAL_SIGNATURE(string memory _title, uint48 _timestamp) pure returns(bytes32 KEY) {
  KEY = bytes32(bytes.concat(_MULTISIG_PROPOSAL_KEY_BYTES4_PREFIX, bytes6(_timestamp), bytes20(bytes(_title))));
}

// Get proposal signature prefix.
function _MULTISIG_PROPOSAL_SIGNATURE_PREFIX(string memory _title, uint48 _timestamp) pure returns(bytes16 KEY_PREFIX) {
  KEY_PREFIX = bytes16(_MULTISIG_PROPOSAL_SIGNATURE(_title, _timestamp));
}

// keccak256("MultisigProposalTargets")
bytes16 constant _MULTISIG_TARGETS_SUFFIX = 0x81e946b6d7a7e0baca88491a44167a59;

// Proposal targets := _MULTISIG_PROPOSAL_SIGNATURE_PREFIX + bytes16(keccak256("MultisigProposalTargets"))
function _MULTISIG_PROPOSAL_TARGETS_KEY(string memory _title, uint48 _timestamp) pure returns(bytes32 KEY) {
  KEY = bytes32(bytes.concat(
    _MULTISIG_PROPOSAL_SIGNATURE_PREFIX(_title, _timestamp),
    _MULTISIG_TARGETS_SUFFIX
  ));
}

// keccak256("MultisigProposalDatas")
bytes16 constant _MULTISIG_DATAS_SUFFIX = 0x6b3ef8384bb94a894d92588af704ec30;

// Proposal targets := _MULTISIG_PROPOSAL_SIGNATURE_PREFIX + bytes16(keccak256("MultisigProposalDatas"))
function _MULTISIG_PROPOSAL_DATAS_KEY(string memory _title, uint48 _timestamp) pure returns(bytes32 KEY) {
  KEY = bytes32(bytes.concat(
    _MULTISIG_PROPOSAL_SIGNATURE_PREFIX(_title, _timestamp),
    _MULTISIG_DATAS_SUFFIX
  ));
}
