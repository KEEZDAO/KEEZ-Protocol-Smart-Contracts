// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";
import {ILSP6KeyManager} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/ILSP6KeyManager.sol";
import {ILSP7DigitalAsset} from "@lukso/lsp-smart-contracts/contracts/LSP7DigitalAsset/ILSP7DigitalAsset.sol";
import {ILSP8IdentifiableDigitalAsset} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/ILSP8IdentifiableDigitalAsset.sol";
import {
  NoPermissionsSet,
  NotAuthorised
} from "@lukso/lsp-smart-contracts/contracts/LSP6KeyManager/LSP6Errors.sol";
import {
  _LSP6KEY_ADDRESSPERMISSIONS_VAULTPERMISSIONS_PREFIX,
  
  _PERMISSION_INCREASE_TOKEN_ALLOWANCE,
  _PERMISSION_ALLOWED_TOKENS_CONTROLLER,
  _PERMISSION_TOKENS_TRANSFER
} from "./VaultConstants.sol";

/**
 *
* @notice This smart contract is responsible for managing the Vault Keys.
 *
 * @author B00ste
 * @title VaultKeyManager
 * @custom:version 1
 */
contract VaultKeyManager {

  /**
   * @notice Address of the DAO_ACCOUNT.
   */
  address payable private UNIVERSAL_PROFILE;

  /**
   * @notice Address of the KEY_MANAGER.
   */
  address private KEY_MANAGER;

  /**
   * @notice Address of the creator.
   */
  address private CREATOR;

  constructor(
    address payable _UNIVERSAL_PROFILE,
    address _KEY_MANAGER
  ) {
    UNIVERSAL_PROFILE = _UNIVERSAL_PROFILE;
    KEY_MANAGER = _KEY_MANAGER;
  }

  /**
   * @notice Add a LSP7/LSP8 to the allowed tokens to be received.
   */
  function addTokenAddressToTheAllowedArray(
    address _tokenAddress
  ) external {
    _verifyPermission(msg.sender, _PERMISSION_ALLOWED_TOKENS_CONTROLLER, "ALLOWED_TOKENS_CONTROLLER");

  }

  /**
   * @notice Increase the allowance of an address to transfer a LSP7 from vault.
   */
  function increaseLSP7Allowance(
    address _tokenAddress,
    address _to,
    uint256 _amount
  ) external{
    _verifyPermission(msg.sender, _PERMISSION_INCREASE_TOKEN_ALLOWANCE, "INCREASE_TOKEN_ALLOWANCE");
    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSignature(
        "execute(uint256,address,uint256,bytes)",
        1,
        _tokenAddress,
        0,
        abi.encodeWithSignature(
          "authorizeOperator(address,uint256)",
          address(this),
          _to,
          _amount
        )
      )
    );
  }

  /**
   * @notice Increase the allowance of an address to transfer a LSP8 from vault.
   */
  function increaseLSP8Allowance(
    address _tokenAddress,
    address _to,
    bytes32 _tokenId
  ) external{
    _verifyPermission(msg.sender, _PERMISSION_INCREASE_TOKEN_ALLOWANCE, "INCREASE_TOKEN_ALLOWANCE");
    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSignature(
        "execute(uint256,address,uint256,bytes)",
        1,
        _tokenAddress,
        0,
        abi.encodeWithSignature(
          "authorizeOperator(address,bytes32)",
          address(this),
          _to,
          _tokenId
        )
      )
    );
  }

  /**
   * @notice Transfer any LSP7 from this contract.
   * Must have TOKEN_TRANSFER permission.
   */
  function transferLSP7(
    address _tokenAddress,
    address _to,
    uint256 _amount,
    bool _force, 
    bytes memory _data
  ) external {
    _verifyPermission(msg.sender, _PERMISSION_TOKENS_TRANSFER, "TOKEN_TRANSFER");
    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSignature(
        "execute(uint256,address,uint256,bytes)",
        1,
        _tokenAddress,
        0,
        abi.encodeWithSignature(
          "transfer(address,address,uint256,bool,bytes)",
          UNIVERSAL_PROFILE,
          _to,
          _amount,
          _force,
          _data
        )
      )
    );
  }

  /**
   * @notice Transfer any LSP8 from this contract.
   * Must have TOKEN_TRANSFER permission.
   */
  function transferLSP8(
    address _tokenAddress,
    address _to,
    bytes32 _tokenId,
    bool _force, 
    bytes memory _data
  ) external {
    _verifyPermission(msg.sender, _PERMISSION_TOKENS_TRANSFER, "TOKEN_TRANSFER");
    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSignature(
        "execute(uint256,address,uint256,bytes)",
        1,
        _tokenAddress,
        0,
        abi.encodeWithSignature(
          "transfer(address,address,bytes32,bool,bytes)",
          UNIVERSAL_PROFILE,
          _to,
          _tokenId,
          _force,
          _data
        )
      )
    );
  }

  /**
   * @notice Batch transfer any LSP7 from this contract.
   * Must have TOKEN_TRANSFER permission.
   */
  function batchTransferLSP7(
    address _tokenAddress,
    address[] memory _to,
    uint256[] memory _amount,
    bool _force, 
    bytes[] memory _data
  ) external {
    _verifyPermission(msg.sender, _PERMISSION_TOKENS_TRANSFER, "TOKEN_TRANSFER");
    address[] memory _from = new address[](_to.length);
    for(uint256 i = 0; i < _to.length; i++) _from[i] = UNIVERSAL_PROFILE;
    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSignature(
        "execute(uint256,address,uint256,bytes)",
        1,
        _tokenAddress,
        0,
        abi.encodeWithSignature(
          "transfer(address[],address[],uint256[],bool,bytes[])",
          _from,
          _to,
          _amount,
          _force,
          _data
        )
      )
    );
  }

  /**
   * @notice Batch transfer any LSP8 from this contract.
   * Must have TOKEN_TRANSFER permission.
   */
  function batchTransferLSP8(
    address _tokenAddress,
    address[] memory _to,
    bytes32[] memory _tokenId,
    bool _force, 
    bytes[] memory _data
  ) external {
    _verifyPermission(msg.sender, _PERMISSION_TOKENS_TRANSFER, "TOKEN_TRANSFER");
    address[] memory _from = new address[](_to.length);
    for(uint256 i = 0; i < _to.length; i++) _from[i] = UNIVERSAL_PROFILE;
    ILSP6KeyManager(KEY_MANAGER).execute(
      abi.encodeWithSignature(
        "execute(uint256,address,uint256,bytes)",
        1,
        _tokenAddress,
        0,
        abi.encodeWithSignature(
          "transfer(address[],address[],bytes32[],bool,bytes[])",
          _from,
          _to,
          _tokenId,
          _force,
          _data
        )
      )
    );
  }


  // --- Internal Methods.


  /**
   * @dev Get the BitArray permissions of an address.
   */
  function _getPermissions(
    address _from
  )
    internal
    view
    returns(bytes32 permissions)
  {
    permissions = bytes32(IERC725Y(UNIVERSAL_PROFILE).getData(bytes32(bytes.concat(
      _LSP6KEY_ADDRESSPERMISSIONS_VAULTPERMISSIONS_PREFIX,
      bytes20(_from)
    ))));
  }

  /**
   * @dev Verify if an address has certain permission and revert if not.
   */
  function _verifyPermission(
    address _from,
    bytes32 _permission,
    string memory _permissionName
  )
    internal
    view
  {
    bytes32 permissions = _getPermissions(_from);
    if(permissions & _permission == 0) revert NotAuthorised(_from, _permissionName);
  }

}