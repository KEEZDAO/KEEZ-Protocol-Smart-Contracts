// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAsset.sol";

/**
 * @author B00ste
 * @title TransferableDaoToken
 * @custom:version 0.1
 */
contract TransferableDaoToken is LSP8IdentifiableDigitalAsset {

  /**
   * @notice The address of the protocol that is allowed to recieve and send tokens.
   */
  address protocolAddress;

  /**
   * @notice Latest tokenId minted.
   */
  uint256 latestTokenId = 0;

  /**
   * @notice Initializing LSP8IdentifiableDigitalAsset 
   */
  constructor(
    string memory name,
    string memory symbol,
    address _protocolAddress
  )
    LSP8IdentifiableDigitalAsset(name, symbol, msg.sender)
  {
    protocolAddress = _protocolAddress;
  }

  /**
   * @notice Mint a new NFT.
   *
   * @param data Information stored in a string that will be encoded using abi.encode().
   */
  function mint(
    string memory data
  ) external {

    latestTokenId++;
    _mint(
      protocolAddress,
      bytes32(latestTokenId),
      true,
      bytes.concat(abi.encode(data))
    );

  }

  /**
   * @notice Override transfers to allow only transfers to or from the `protocolAddress`
   */
  function _transfer(
    address from,
    address to,
    bytes32 tokenId,
    bool force,
    bytes memory data
  ) internal override {

    require(
      to == protocolAddress || from == protocolAddress,
      "Nor sender, nor reciever is the protocol."
    );

    super._transfer(
      from,
      to,
      tokenId,
      force,
      data
    );

  }

}