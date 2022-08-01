// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;


// --- LSP6KeyManager KEYS


// keccak256("AddressPermissions[]")
bytes32 constant _LSP6KEY_ADDRESSPERMISSIONS_ARRAY = 0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3;

// AddressPermissions[index]
bytes16 constant _LSP6KEY_ADDRESSPERMISSIONS_ARRAY_PREFIX = 0xdf30dba06db6a30e65354d9a64c60986;

// AddressPermissions:...
bytes6 constant _LSP6KEY_ADDRESSPERMISSIONS_PREFIX = 0x4b80742de2bf;


// --- VAULT PERMISSIONS KEYS


// bytes6(keccak256("AddressPermissions")) + bytes4(keccak256("VaultPermissions")) + bytes2(0)
// AddressPermissions:VaultPermissions:<address> --> bytes32
bytes12 constant _LSP6KEY_ADDRESSPERMISSIONS_VAULTPERMISSIONS_PREFIX = 0x4164647265735661756c0000;

// DEFAULT PERMISSIONS VALUES
bytes32 constant _PERMISSION_INCREASE_TOKEN_ALLOWANCE  = 0x0000000000000000000000000000000000000000000000000000000000000001;
bytes32 constant _PERMISSION_ALLOWED_TOKENS_CONTROLLER = 0x0000000000000000000000000000000000000000000000000000000000000002;
bytes32 constant _PERMISSION_TOKENS_TRANSFER           = 0x0000000000000000000000000000000000000000000000000000000000000004;


// --- ALLOWED ADDRESSES KEYS


// keccak256("AllowedTokenAddresses[]")
bytes32 constant _VAULT_ALLOWED_TOKEN_ADDRESSES = 0x76be1d71971a3827f349fb03e23df86915b1a2cdaddd9ef737d0e40ab7893789;

// AllowedTokenAddresses[index]
bytes16 constant _VAULT_ALLOWED_TOKEN_ADDRESSES_PREFIX = 0x76be1d71971a3827f349fb03e23df869;