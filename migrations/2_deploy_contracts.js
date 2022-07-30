const LSP0ERC725Account = artifacts.require("LSP0ERC725Account");
const LSP6KeyManager = artifacts.require("LSP6KeyManager");
const DaoKeyManager = artifacts.require("DaoKeyManager");
const VaultKeyManager = artifacts.require("VaultKeyManager");
const MultisigKeyManager = artifacts.require("MultisigKeyManager");
const web3 = require("web3");

module.exports = async function(deployer, networks, accounts) {

  await deployer.deploy(LSP0ERC725Account, accounts[0]);
  const UNIVERSAL_PROFILE = await LSP0ERC725Account.deployed();

  await deployer.deploy(LSP6KeyManager, UNIVERSAL_PROFILE.address);
  const KEY_MANAGER = await LSP6KeyManager.deployed();

  await deployer.deploy(DaoKeyManager, UNIVERSAL_PROFILE.address, KEY_MANAGER.address);
  const DAO_KEY_MANAGER = await DaoKeyManager.deployed();

  await deployer.deploy(VaultKeyManager, UNIVERSAL_PROFILE.address, KEY_MANAGER.address);
  const VAULT_KEY_MANAGER = await VaultKeyManager.deployed();

  await deployer.deploy(MultisigKeyManager, UNIVERSAL_PROFILE.address, KEY_MANAGER.address);
  const MULTISIG_KEY_MANAGER = await MultisigKeyManager.deployed();

  let keys = [
    "0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3",
    "0xdf30dba06db6a30e65354d9a64c60986" + "00000000000000000000000000000000",
    "0xdf30dba06db6a30e65354d9a64c60986" + "00000000000000000000000000000001",
    "0xdf30dba06db6a30e65354d9a64c60986" + "00000000000000000000000000000002",
    "0xdf30dba06db6a30e65354d9a64c60986" + "00000000000000000000000000000003",
    "0x4b80742de2bf82acb3630000" + DAO_KEY_MANAGER.address.toString().substring(2),
    "0x4b80742de2bf82acb3630000" + VAULT_KEY_MANAGER.address.toString().substring(2),
    "0x4b80742de2bf82acb3630000" + MULTISIG_KEY_MANAGER.address.toString().substring(2),
    "0x4b80742de2bf82acb3630000" + accounts[0].toString().substring(2),
    "0xbc776f168e7b9c60bb2a7180950facd372cd90c841732d963c31a93ff9f8c127",
    "0xbc776f168e7b9c60bb2a7180950facd372cd90c841732d963c31a93ff9f8c127",
    "0xf89f507ecd9cb7646ce1514ec6ab90d695dac9314c3771f451fd90148a3335a9",
    "0x5bd05fa174be6a4aa4a8222f8837a27a381de14e7797cf7945df58b0626e6c3d",
    "0xd08ca3a83d59467dd8ba57e940549874ea8310a1ebfb4396959235b00035d777"
  ];

  let values = [
    "0x0000000000000000000000000000000000000000000000000000000000000004",
    DAO_KEY_MANAGER.address,
    VAULT_KEY_MANAGER.address,
    MULTISIG_KEY_MANAGER.address,
    accounts[0],
    "0x0000000000000000000000000000000000000000000000000000000000007FFF",
    "0x0000000000000000000000000000000000000000000000000000000000007FFF",
    "0x0000000000000000000000000000000000000000000000000000000000007FFF",
    "0x0000000000000000000000000000000000000000000000000000000000000001",
    web3.utils.utf8ToHex("https://somerandomlink.com"),
    web3.utils.numberToHex(50),
    web3.utils.numberToHex(50),
    web3.utils.numberToHex(120),
    web3.utils.numberToHex(120)
  ];

  console.log(keys);
  console.log(values);

  const set_data = await UNIVERSAL_PROFILE.methods["setData(bytes32[],bytes[])"](keys, values);
  const transfer_ownership = await UNIVERSAL_PROFILE.transferOwnership(KEY_MANAGER.address);
  const bytes4_claimOwnership = web3.utils.keccak256('claimOwnership()').substring(0, 10);
  const claim_ownership = await KEY_MANAGER.execute(bytes4_claimOwnership);

};