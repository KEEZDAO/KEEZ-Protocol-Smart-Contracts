// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.10;

// A default error that returns the caller and a error number stored in a bytes2 variable.
error IndexedError(string contractName, bytes1 errorNumber);
