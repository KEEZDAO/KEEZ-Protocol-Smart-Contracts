var LSP0ERC725Account = artifacts.require("LSP0ERC725Account");
var LSP6KeyManager = artifacts.require("LSP6KeyManager");
var DaoKeyManager = artifacts.require("DaoKeyManager");
var VaultKeyManager = artifacts.require("VaultKeyManager");
var MultisigKeyManager = artifacts.require("MultisigKeyManager");

module.exports = async function(deployer, networks, accounts) {

  await deployer.deploy(LSP0ERC725Account, accounts[0]);
  const UNIVERSAL_PROFILE = await LSP0ERC725Account.deployed();

  await deployer.deploy(LSP6KeyManager, UNIVERSAL_PROFILE.address);
  const KEY_MANAGER = await LSP6KeyManager.deployed();

  await deployer.deploy(DaoKeyManager, UNIVERSAL_PROFILE.address, KEY_MANAGER.address);
  const DAO_KEY_MANAGER = await DaoKeyManager.deployed();

  await deployer.deploy(VaultKeyManager);
  const VAULT_KEY_MANAGER = await VaultKeyManager.deployed();

  console.log(UNIVERSAL_PROFILE);

  //await deployer.deploy(MultisigKeyManager);
  //const MULTISIG_KEY_MANAGER = await MultisigKeyManager.deployed();

  let keys = [];
  keys[0] = "0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3";
  keys[1] = "0xdf30dba06db6a30e65354d9a64c60986" + "00000000000000000000000000000000";
  keys[2] = "0xdf30dba06db6a30e65354d9a64c60986" + "00000000000000000000000000000001";
  keys[3] = "0xdf30dba06db6a30e65354d9a64c60986" + "00000000000000000000000000000002";
  keys[4] = "0x4b80742de2bf82acb3630000" + DAO_KEY_MANAGER.address.toString().substring(2);
  keys[5] = "0x4b80742de2bf82acb3630000" + VAULT_KEY_MANAGER.address.toString().substring(2);
  keys[6] = "0x4b80742de2bf82acb3630000" + accounts[0].toString().substring(2);
  
  let values = [];
  values[0] = "0x0000000000000000000000000000000000000000000000000000000000000002";
  values[1] = DAO_KEY_MANAGER.address;
  values[2] = VAULT_KEY_MANAGER.address;
  values[3] = accounts[0];
  values[4] = "0x0000000000000000000000000000000000000000000000000000000000007FFF";
  values[5] = "0x0000000000000000000000000000000000000000000000000000000000007FFF";
  values[6] = "0x0000000000000000000000000000000000000000000000000000000000000001";

  UNIVERSAL_PROFILE.methods["setData(bytes32[],bytes[])"](keys, values);
  
  

};