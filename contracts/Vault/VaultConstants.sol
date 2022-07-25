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

// bytes6(keccak256("AddressPermissions")) + bytes4(keccak256("VaultPermissions")) + bytes2(0)
// AddressPermissions:VaultPermissions:<address> --> bytes32
bytes12 constant _LSP6KEY_ADDRESSPERMISSIONS_VAULTPERMISSIONS_PREFIX = 0x4b80742de2bfb3cc0e490000;

// DEFAULT PERMISSIONS VALUES
bytes32 constant _PERMISSION_VOTE             = 0x0000000000000000000000000000000000000000000000000000000000000001;
bytes32 constant _PERMISSION_PROPOSE          = 0x0000000000000000000000000000000000000000000000000000000000000002;


