// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// --- LSP6KeyManager KEYS


// keccak256("AddressPermissions[]")
bytes32 constant _LSP6KEY_ADDRESSPERMISSIONS_ARRAY = 0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3;

// AddressPermissions[index]
bytes16 constant _LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX = 0xdf30dba06db6a30e65354d9a64c60986;

// AddressPermissions:...
bytes6 constant _LSP6KEY_ADDRESSPERMISSIONS_PREFIX = 0x4b80742de2bf;


// --- PERMISSIONS KEYS


// bytes6(keccak256("AddressPermissions")) + bytes4(keccak256("MultisigPermissions")) + bytes2(0)
// AddressPermissions:MultisigPermissions:<address> --> bytes32
bytes12 constant _LSP6KEY_ADDRESSPERMISSIONS_MULTISIGPERMISSIONS_PREFIX = 0x4164647265734d756c740000;

// DEFAULT PERMISSIONS VALUES
bytes32 constant _PERMISSION_VOTE              = 0x0000000000000000000000000000000000000000000000000000000000000001;
bytes32 constant _PERMISSION_PROPOSE           = 0x0000000000000000000000000000000000000000000000000000000000000002;
bytes32 constant _PERMISSION_ADD_PERMISSION    = 0x0000000000000000000000000000000000000000000000000000000000000004;
bytes32 constant _PERMISSION_REMOVE_PERMISSION = 0x0000000000000000000000000000000000000000000000000000000000000008;

// --- MULTISIG SETTINGS


// keccak256("MultisigJSONMetadata")
bytes32 constant _MULTISIG_JSON_METADATA_KEY = 0xa175306945481d092127a6c47d28cb3185da752d20388c1682ff11fce1017356;

// keccak256("MultisigQuorum")
bytes32 constant _MULTISIG_QUORUM_KEY = 0x47499aa724781173ffff2a8a82c6223b88e1a838d32bb91a9ff9c9c0b8c8759b;


// --- PARTICIPATION KEYS


// keccak256("MultisigParticipants[]")
bytes32 constant _MULTISIG_PARTICIPANTS_ARRAY_KEY = 0x54aef89da199194b126d28036f71291726191dbff7160f9d0986952b17eaedb4;

// MultisigParticipants[index]
bytes16 constant _MULTISIG_PARTICIPANTS_ARRAY_PREFIX = 0x54aef89da199194b126d28036f712917;

// MultisigParticipants:<address> --> index
bytes10 constant _MULTISIG_PARTICIPANTS_MAPPING_PREFIX = 0x54aef89da199194b126d;


// --- PROPOSAL KEYS


// keccak("MultisigProposal")
bytes4 constant _MULTISIG_PROPOSAL_KEY_BYTES4_PREFIX = 0x4d756c74;

// Proposal signature := _MULTISIG_PROPOSAL_KEY_PREFIX + bytes6(abi.encode(<Creation Timestamp>))
function _MULTISIG_PROPOSAL_SIGNATURE(uint48 _timestamp) pure returns(bytes10 KEY) {
  KEY = bytes10(bytes.concat(_MULTISIG_PROPOSAL_KEY_BYTES4_PREFIX, bytes6(keccak256(abi.encode(_timestamp)))));
}

// keccak256("MultisigProposalTargets[]")
bytes20 constant _MULTISIG_TARGETS_SUFFIX = bytes20(keccak256("MultisigProposalTargets[]"));
//bytes20 constant _MULTISIG_TARGETS_SUFFIX = 0xc6c66d5a29ded4b70a2bc4d1637290a99598996b;

// Proposal targets := _MULTISIG_PROPOSAL_SIGNATURE + bytes2(0) + bytes20(keccak256("MultisigProposalTargets"))
// --> abi.encode(address[])
function _MULTISIG_PROPOSAL_TARGETS_KEY(bytes10 _proposalSignature) pure returns(bytes32 KEY) {
  KEY = bytes32(bytes.concat(
    _proposalSignature,
    bytes2(0),
    _MULTISIG_TARGETS_SUFFIX
  ));
}

// keccak256("MultisigProposalDatas[]")
bytes20 constant _MULTISIG_DATAS_SUFFIX = bytes20(keccak256("MultisigProposalDatas[]"));
//bytes20 constant _MULTISIG_DATAS_SUFFIX = 0xa127ec6f6a314082d85a8df20cec2eb66abc0e15;

// Proposal targets := _MULTISIG_PROPOSAL_SIGNATURE + bytes2(0) + bytes20(keccak256("MultisigProposalDatas"))
// --> abi.encode(bytes[])
function _MULTISIG_PROPOSAL_DATAS_KEY(bytes10 _proposalSignature) pure returns(bytes32 KEY) {
  KEY = bytes32(bytes.concat(
    _proposalSignature,
    bytes2(0),
    _MULTISIG_DATAS_SUFFIX
  ));
}
