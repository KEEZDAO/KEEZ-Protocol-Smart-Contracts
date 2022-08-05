// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// setData(bytes32,bytes)
bytes4 constant setDataSingleSelector = bytes4(keccak256("setData(bytes32,bytes)"));

// setData(bytes32[],bytes[])
bytes4 constant setDataMultipleSelector = bytes4(keccak256("setData(bytes32[],bytes[])"));

// LSP7: authorizeOperator()
bytes4 constant authotizeOperatorLSP7 = bytes4(keccak256("authorizeOperator(address,uint256)"));

// LSP8: authorizeOperator()
bytes4 constant authotizeOperatorLSP8 = bytes4(keccak256("authorizeOperator(address,bytes32)"));

// LSP7: revokeOperator(address)
bytes4 constant revokeOperatorLSP7 = bytes4(keccak256("revokeOperator(address)"));

// LSP8: revokeOperator(address,bytes32)
bytes4 constant revokeOperatorLSP8 = bytes4(keccak256("revokeOperator(address,bytes32)"));

// LSP7: transfer()
bytes4 constant transferLSP7 = bytes4(keccak256("transfer(address,address,uint256,bool,bytes)"));

// LSP8: transfer()
bytes4 constant transferLSP8 = bytes4(keccak256("transfer(address,address,bytes32,bool,bytes)"));

// LSP7: transferBatch()
bytes4 constant transferBatchLSP7 = bytes4(keccak256("transferBatch(address[],address[],uint256[],bool,bytes[])"));

// LSP8: transferBatch()
bytes4 constant transferBatchLSP8 = bytes4(keccak256("transferBatch(address[],address[],bytes32[],bool,bytes[])"));