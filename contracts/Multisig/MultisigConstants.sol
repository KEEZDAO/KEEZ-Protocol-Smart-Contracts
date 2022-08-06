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
bytes32 constant _PERMISSION_EXECUTE_PROPOSAL  = 0x0000000000000000000000000000000000000000000000000000000000000010;


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
bytes12 constant _MULTISIG_PARTICIPANTS_MAPPING_PREFIX = 0x54aef89da199194b126d0000;


// --- PROPOSAL KEYS


// keccak("MultisigProposal")
bytes4 constant _MULTISIG_PROPOSAL_KEY_BYTES4_PREFIX = 0x4d756c74;

// Proposal identifier := bytes6(keccak256(abi.encode(<Proposal title>, <Proposal timestamp>)))
// Proposal signature := _DAO_PROPOSAL_KEY_BYTES4_PREFIX + <Proposal identifier>
function _MULTISIG_PROPOSAL_SIGNATURE(bytes6 _proposalIdentifier) pure returns(bytes10 KEY) {
  KEY = bytes10(bytes.concat(_MULTISIG_PROPOSAL_KEY_BYTES4_PREFIX, _proposalIdentifier));
}

// bytes2(0) + bytes20(keccak256("MultisigProposalPayloads"))
bytes22 constant _MULTISIG_PAYLOADS_SUFFIX = 0x0000870a9bfe5ccee436bab5b4cfd8215400bb038e8e;

// Proposal payloads := _MULTISIG_PROPOSAL_SIGNATURE + bytes2(0) + bytes20(keccak256("MultisigProposalPayloads"))
// --> abi.encode(bytes[])
function _MULTISIG_PROPOSAL_PAYLOADS_KEY(bytes10 _proposalSignature) pure returns(bytes32 KEY) {
  KEY = bytes32(bytes.concat(
    _proposalSignature,
    _MULTISIG_PAYLOADS_SUFFIX
  ));
}
