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

// bytes6(keccak256("AddressPermissions")) + bytes4(keccak256("DaoPermissions")) + bytes2(0)
// AddressPermissions:DaoPermissions:<address> --> bytes32
bytes12 constant _LSP6KEY_ADDRESSPERMISSIONS_DAOPERMISSIONS_PREFIX = 0x4b80742de2bfb3cc0e490000;

// DEFAULT PERMISSIONS VALUES
bytes32 constant _PERMISSION_VOTE             = 0x0000000000000000000000000000000000000000000000000000000000000001;
bytes32 constant _PERMISSION_PROPOSE          = 0x0000000000000000000000000000000000000000000000000000000000000002;
bytes32 constant _PERMISSION_EXECUTE          = 0x0000000000000000000000000000000000000000000000000000000000000004;
bytes32 constant _PERMISSION_SENDDELEGATE     = 0x0000000000000000000000000000000000000000000000000000000000000008;
bytes32 constant _PERMISSION_RECIEVEDELEGATE  = 0x0000000000000000000000000000000000000000000000000000000000000010;

// SUPER PERMISSIONS VALUES
bytes32 constant _PERMISSION_SUPERVOTE        = 0x0000000000000000000000000000000000000000000000000000000000000020;
bytes32 constant _PERMISSION_SUPERPROPOSE     = 0x0000000000000000000000000000000000000000000000000000000000000040;
bytes32 constant _PERMISSION_MASTER           = 0x0000000000000000000000000000000000000000000000000000000000000080;


// --- DAO ACCOUNT METDATA KEYS


// keccak256("Title")
bytes32 constant _KEY_TITLE = 0x3f82a2b5852cbedcda3d9062384397479ac9a00dae9991874d842bec7aab98ce; // --> string

// keccak256("Description")
bytes32 constant _KEY_DESCRIPTION = 0x95e794640ff3efd16bfe738f1a9bf2886d166af549121f57d6e14af6b513f45d; // --> string

// keccak256("Majority")
bytes32 constant _KEY_MAJORITY = 0xbc776f168e7b9c60bb2a7180950facd372cd90c841732d963c31a93ff9f8c127; // --> uint8

// keccak256("ParticipationRate")
bytes32 constant _KEY_PARTICIPATIONRATE = 0xf89f507ecd9cb7646ce1514ec6ab90d695dac9314c3771f451fd90148a3335a9; // --> uint8

// keccak256("VotingDelay")
bytes32 constant _KEY_VOTINGDELAY = 0x5bd05fa174be6a4aa4a8222f8837a27a381de14e7797cf7945df58b0626e6c3d; // --> uint256

// keccak256("VotingPeriod")
bytes32 constant _KEY_VOTINGPERIOD = 0xd08ca3a83d59467dd8ba57e940549874ea8310a1ebfb4396959235b00035d777; // --> uint256

// keccak256("TokenGatedDao")
// non-token = 0000 0000; transferable-token = 0000 0001; non-transferable-token = 0000 0010;
bytes32 constant _KEY_TOKENGATED = 0xa45b1e711ab5d2d7654c92da78c9148c51fb0a58b116afda9fbf612c88e9680d; // --> bytes1(BitArray)


// --- DAO DELEGATING KEYS


// bytes10(keccak256("DelegtateTo")) + bytes2(0)
bytes12 constant _KEY_DELEGATEVOTE = 0x0a30e74a6c7868e400140000; // DelegateTo:<address> --> address

// bytes10(keccak256("AddressDelegates[]")) + bytes2(0)
bytes12 constant _KEY_ADDRESSDELEGATES_ARRAY_PREFIX = 0xc3f797d5c8ae536b82a60000; // AddressDelegates[]:<address> --> uint128 (ArrayLength)

// AddressDelegates[index]
// _SPLIT_BYTES32_IN_TWO_HALFS(AddressDelegates[]:<address>) + bytes16(index) --> address
function _KEY_ADDRESSDELEGATES_ARRAY_INDEX_PREFIX(address delegateeAddress) pure returns(bytes16 KEY_PREFIX) {
  KEY_PREFIX = _SPLIT_BYTES32_IN_TWO_HALFS(
    bytes32(bytes.concat(
      _KEY_ADDRESSDELEGATES_ARRAY_PREFIX,
      bytes20(delegateeAddress)
    ))
  )[0];
}


// --- DAO PROPOSAL KEYS


// To access the Proposal Data you need the bytes10(ProposalSignature) + bytes22(DataSuffix)

// ProposalSignature := bytes6(uint48(creationTimestamp)) + bytes4(keccak256(bytes(Title)))
function _KEY_PROPOSAL_PREFIX(uint48 creationTimestamp, bytes32 title) pure returns(bytes10 KEY_PREFIX) {
  KEY_PREFIX = bytes10(bytes.concat(bytes6(uint48(creationTimestamp)), bytes4(keccak256(bytes.concat(title)))));
}

// bytes2(0) + bytes20(keccak256("Title")) --> bytes32
bytes22 constant _KEY_PROPOSAL_TITLE_SUFFIX = 0x00003f82a2b5852cbedcda3d9062384397479ac9a00d;

// bytes2(0) + bytes20(keccak256("Description")) --> string
bytes22 constant _KEY_PROPOSAL_DESCRIPTION_SUFFIX = 0x000095e794640ff3efd16bfe738f1a9bf2886d166af5;

// bytes2(0) + bytes20(keccak256("CreationTimestamp")) --> uint256
bytes22 constant _KEY_PROPOSAL_CREATIONTIMESTAMP_SUFFIX = 0x0000bd3132afbfa232f7d171a873f7e52e32c666b06d;

// bytes2(0) + bytes20(keccak256("TargetsArray[]")) --> address[]
bytes22 constant _KEY_PROPOSAL_TARGETSARRAY_SUFFIX = 0x0000ba6d4933d1a0fbfd29728a3ed8d0a7aca50635b5; 

// bytes2(0) + bytes20(keccak256("DatasArray[]")) --> bytes[]
bytes22 constant _KEY_PROPOSAL_DATASARRAY_SUFFIX = 0x0000478499bb6846f8a28632137c772be842c41b3105;

// bytes2(0) + bytes20(keccak256("ProposalChoices")) --> uint8
bytes22 constant _KEY_PROPOSAL_PROPOSALCHOICES_SUFFIX = 0x0000e5dd8acc7154a678a0a3fa3fe2d65b8700bf702c;

// bytes2(0) + bytes20(keccak256("MaximumChoicesPerVote")) --> uint8
bytes22 constant _KEY_PROPOSAL_MAXIMUMCHOICESPERVOTE_SUFFIX = 0x0000ed458cca63dcf8476211a40ad15420dcabc377f0;

// ParticipantVoteKey := bytes10(ProposalSignature) + bytes2(0) + bytes20(participantAddress)
// --> bytes30 vote description and bytes2 16 different choices in BitArray
function _KEY_PARTICIPANT_VOTE(bytes10 proposalSignature, address participantAddress) pure returns(bytes32 KEY) {
  KEY = bytes32(bytes.concat(bytes10(proposalSignature), bytes2(0), bytes20(participantAddress)));
}


/// @dev see IERC725Y interface
///      https://github.com/ERC725Alliance/ERC725/blob/main/implementations/contracts/interfaces/IERC725Y.sol
bytes4 constant setDataSingleSelector = bytes4(keccak256("setData(bytes32,bytes)"));
bytes4 constant setDataMultipleSelector = bytes4(keccak256("setData(bytes32[],bytes[])"));

// Input: 0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3
// Output: [0xdf30dba06db6a30e65354d9a64c60986, 0x1f089545ca58c6b4dbe31a5f338cb0e3]
function _SPLIT_BYTES32_IN_TWO_HALFS(bytes32 source) pure returns(bytes16[2] memory halfs) {
  halfs = [bytes16(0), 0];
  assembly {
      mstore(halfs, source)
      mstore(add(halfs, 16), source)
  }
}