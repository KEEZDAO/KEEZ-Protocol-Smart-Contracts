// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.10;

// --- ERC165 interface ids
bytes4 constant _INTERFACEID_LSP6 = 0xc403d48f;


// --- PERMISSIONS KEYS


// keccak256("AddressPermissions[]")
bytes32 constant _LSP6KEY_ADDRESSPERMISSIONS_ARRAY = 0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3;

// AddressPermissions[index]
bytes16 constant _LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX = 0xdf30dba06db6a30e65354d9a64c60986;

// AddressPermissions:...
bytes6 constant _LSP6KEY_ADDRESSPERMISSIONS_PREFIX = 0x4b80742de2bf;

// bytes6(keccak256("AddressPermissions")) + bytes4(keccak256("DaoPermissions")) + bytes2(0)
// AddressPermissions:DaoPermissions:<address> --> bytes32
bytes12 constant _LSP6KEY_ADDRESSPERMISSIONS_DAOPERMISSIONS_PREFIX = 0x4b80742de2bfb3cc0e490000;

// DEFAULT PERMISSIONS VALUES
bytes32 constant _PERMISSION_VOTE                = 0x0000000000000000000000000000000000000000000000000000000000000001;
bytes32 constant _PERMISSION_PROPOSE             = 0x0000000000000000000000000000000000000000000000000000000000000002;
bytes32 constant _PERMISSION_EXECUTE             = 0x0000000000000000000000000000000000000000000000000000000000000004;
bytes32 constant _PERMISSION_SEND_DELEGATE       = 0x0000000000000000000000000000000000000000000000000000000000000008;
bytes32 constant _PERMISSION_RECIEVE_DELEGATE    = 0x0000000000000000000000000000000000000000000000000000000000000010;
bytes32 constant _PERMISSION_ADD_PERMISSIONS     = 0x0000000000000000000000000000000000000000000000000000000000000020;
bytes32 constant _PERMISSION_REMOVE_PERMISSIONS  = 0x0000000000000000000000000000000000000000000000000000000000000040;
bytes32 constant _PERMISSION_REGISTER_VOTES      = 0x0000000000000000000000000000000000000000000000000000000000000080;


// --- PARTICIPATION KEYS


// keccak256("DaoParticipants[]")
bytes32 constant _DAO_PARTICIPANTS_ARRAY_KEY = 0xf7f9c7410dd493d79ebdaee15bbc77fd163bd488f54107d1be6ed34b1e099004;

// DaoParticipants[index]
bytes16 constant _DAO_PARTICIPANTS_ARRAY_PREFIX = 0xf7f9c7410dd493d79ebdaee15bbc77fd;

// DaoParticipants:<address> --> index
bytes12 constant _DAO_PARTICIPANTS_MAPPING_PREFIX = 0xf7f9c7410dd493d79ebd0000;


// --- DAO DELEGATING KEYS


// bytes10(keccak256("DelegtateTo")) + bytes2(0)
bytes12 constant _DAO_DELEGATEE_PREFIX = 0x0a30e74a6c7868e400140000; // DelegateTo:<address> --> address

// bytes10(keccak256("AddressDelegates")) + bytes2(0)
bytes12 constant _DAO_DELEGATES_ARRAY_PREFIX = 0x92a4ebfa1896d9ad8b430000; // AddressDelegates[]:<address> --> abi.encode(address[])


// --- DAO ACCOUNT METDATA KEYS


// bytes32(keccak256("Majority")) --> uint256
bytes32 constant _DAO_MAJORITY_KEY = 0xbc776f168e7b9c60bb2a7180950facd372cd90c841732d963c31a93ff9f8c127; // --> uint8

// bytes32(keccak256("ParticipationRate")) --> uint256
bytes32 constant _DAO_PARTICIPATION_RATE_KEY = 0xf89f507ecd9cb7646ce1514ec6ab90d695dac9314c3771f451fd90148a3335a9; // --> uint8

// bytes32(keccak256("MinimumVotingDelay")) --> uint256
bytes32 constant _DAO_MINIMUM_VOTING_DELAY_KEY = 0x799787138cc40d7a47af8e69bdea98db14e1ead8227cef96814fa51751e25c76; // --> uint256

// bytes32(keccak256("MinimumVotingPeriod")) --> uint256
bytes32 constant _DAO_MINIMUM_VOTING_PERIOD_KEY = 0xd3cf4cd71858ea36c3f5ce43955db04cbe9e1f42a2c7795c25c1d430c9bb280a; // --> uint256

// bytes32(keccak256("MinimumExecutionDelay)) --> uint256
bytes32 constant _DAO_MINIMUM_EXECUTION_DELAY_KEY = 0xb207580c05383177027a90d6c298046d3d60dfa05a32b0bb48ea9015e11a3424; // --> uint256


// --- DAO PROPOSAL KEYS


// keccak("DaoProposal")
bytes4 constant _DAO_PROPOSAL_KEY_BYTES4_PREFIX = 0xc2802fcf;

// Proposal identifier := bytes6(keccak256(abi.encode(<Proposal title>, <Proposal timestamp>)))
// Proposal signature := _DAO_PROPOSAL_KEY_BYTES4_PREFIX + <Proposal identifier>
function _DAO_PROPOSAL_SIGNATURE(bytes6 _proposalIdentifier) pure returns(bytes10 KEY) {
  KEY = bytes10(bytes.concat(_DAO_PROPOSAL_KEY_BYTES4_PREFIX, _proposalIdentifier));
}

// bytes2(0) + bytes20(keccak256("ProposalMetadataJSON")) --> Website
bytes22 constant _DAO_PROPOSAL_JSON_METADATA_SUFFIX = 0x00004a8279d372333473468a5a28870c140a7941f668;

// bytes2(0) + bytes20(keccak256("ProposalDelay")) --> uint256
bytes22 constant _DAO_PROPOSAL_VOTING_DELAY_SUFFIX = 0x0000cc713dffc839645a02779745d6e8e8cca753795c;

// bytes2(0) + bytes20(keccak256("ProposalVotingPeriod")) --> uint256
bytes22 constant _DAO_PROPOSAL_VOTING_PERIOD_SUFFIX = 0x00006ebe389303905e56ea48aecac1536207791d0e67;

// bytes2(0) + bytes20(keccak256("ProposalExecutionDelay")) --> uint256
bytes22 constant _DAO_PROPOSAL_EXECUTION_DELAY_SUFFIX = 0x0000164526a330a273b37abc4c89336a3042182a3910;

// bytes2(0) + bytes20(keccak256("CreationTimestamp")) --> uint256
bytes22 constant _DAO_PROPOSAL_CREATION_TIMESTAMP_SUFFIX = 0x0000bd3132afbfa232f7d171a873f7e52e32c666b06d;

// bytes2(0) + bytes20(keccak256("PayloadArray")) --> abi.encode(bytes[])
bytes22 constant _DAO_PROPOSAL_PAYLOADS_ARRAY_SUFFIX = 0x0000922cb700268d68a7160e60fe26870af11cd98aaa; 

// bytes2(0) + bytes20(keccak256("ProposalChoices")) --> uint8
bytes22 constant _DAO_PROPOSAL_PROPOSAL_CHOICES_SUFFIX = 0x0000e5dd8acc7154a678a0a3fa3fe2d65b8700bf702c;

// bytes2(0) + bytes20(keccak256("MaximumChoicesPerVote")) --> uint8
bytes22 constant _DAO_PROPOSAL_MAXIMUM_CHOICES_PER_VOTE_SUFFIX = 0x00002d53f22395ee464559c1d5b27661145933a15e8f;

/**
 * <ProposalSignature>:<VoterAddress>
 * This mapping would return a bytes1() which must be equal to 0x01 (meaning voted)
 * or 0x (meaning, didn't vote) 
 */