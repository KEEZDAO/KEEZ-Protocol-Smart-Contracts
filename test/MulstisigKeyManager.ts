import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Lock", function () {
  async function deployContracts() {

    const [owner, account1, account2] = await ethers.getSigners();

    const UniversalReceiverDelegateUP = await ethers.getContractFactory("UniversalReceiverDelegateUP");
    const universalReceiverDelegateUP = await UniversalReceiverDelegateUP.deploy();

    const UniversalReceiverDelegateVault = await ethers.getContractFactory("UniversalReceiverDelegateVault");
    const universalReceiverDelegateVault = await UniversalReceiverDelegateVault.deploy();

    const UniversalProfile = await ethers.getContractFactory("UniversalProfile");
    const universalProfile = await UniversalProfile.deploy(owner.address, universalReceiverDelegateUP.address);

    const Vault = await ethers.getContractFactory("Vault");
    const vault = await Vault.deploy(owner.address, universalReceiverDelegateVault.address);

    const KeyManager = await ethers.getContractFactory("KeyManager");
    const keyManager = await KeyManager.deploy(universalProfile.address);

    const MultisigKeyManager = await ethers.getContractFactory("MultisigKeyManager");
    const multisig = await MultisigKeyManager.deploy(universalProfile.address, keyManager.address);

    const DaoKeyManager = await ethers.getContractFactory("DaoKeyManager");
    const dao = await DaoKeyManager.deploy(universalProfile.address, keyManager.address); 

    return { universalReceiverDelegateUP, universalProfile, vault, keyManager, multisig, dao, owner, account1, account2 };
  }

  describe("Deployment", function () {

    it("Should set universal profile permissions correctly on deployment", async () => {
      const { universalReceiverDelegateUP, universalProfile } = await loadFixture(deployContracts);

      const keys = [
        "0x0cfc51aec37c55a4d0b1a65c6255c4bf2fbdf6277f3cc0730c45b828b6db8b47",
        "0xeafec4d89fa9619884b60000abe425d64acd861a49b8ddf5c0b6962110481f38"
      ];
      const values = [
        universalReceiverDelegateUP.address.toLowerCase(),
        "0xabe425d6"
      ];

      const get_data = await universalProfile["getData(bytes32[])"](keys);
      
      expect(get_data).to.deep.equal(values);
    });

    it("Should set multisig permissions correctly", async () => {
      const { universalProfile, owner, account1, account2 } = await loadFixture(deployContracts);
      
      
      const initializeMultisig = await universalProfile.connect(owner).setMultisigdata(
        ethers.utils.hexlify(ethers.utils.toUtf8Bytes("https://somelink.com/")),
        ethers.utils.hexValue(50),
        [
          owner.address,
          account1.address,
          account2.address
        ],
        [
          "0x000000000000000000000000000000000000000000000000000000000000000f",
          "0x0000000000000000000000000000000000000000000000000000000000000001",
          "0x0000000000000000000000000000000000000000000000000000000000000001"
        ]
      );

      const keys = [
        // metadata of the multisig
        "0xa175306945481d092127a6c47d28cb3185da752d20388c1682ff11fce1017356",
        "0x47499aa724781173ffff2a8a82c6223b88e1a838d32bb91a9ff9c9c0b8c8759b",
        // array length and array elements
        "0x54aef89da199194b126d28036f71291726191dbff7160f9d0986952b17eaedb4",
        "0x54aef89da199194b126d28036f712917" + "00000000000000000000000000000000",
        "0x54aef89da199194b126d28036f712917" + "00000000000000000000000000000001",
        "0x54aef89da199194b126d28036f712917" + "00000000000000000000000000000002",
        // mapping of the addresses
        "0x54aef89da199194b126d0000" + owner.address.substring(2),
        "0x54aef89da199194b126d0000" + account1.address.substring(2),
        "0x54aef89da199194b126d0000" + account2.address.substring(2),
        // permissions of the addresses
        "0x4164647265734d756c740000" + owner.address.substring(2),
        "0x4164647265734d756c740000" + account1.address.substring(2),
        "0x4164647265734d756c740000" + account2.address.substring(2)
      ];
      const values = [
        // metadata of the multisig
        ethers.utils.hexlify(ethers.utils.toUtf8Bytes("https://somelink.com/")),
        ethers.utils.hexValue(50),
        // array length and array elements
        "0x0000000000000000000000000000000000000000000000000000000000000003",
        owner.address.toLowerCase(),
        account1.address.toLowerCase(),
        account2.address.toLowerCase(),
        // mapping of the addresses
        "0x0000000000000000000000000000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000000000000000000000000001",
        "0x0000000000000000000000000000000000000000000000000000000000000002",
        // permissions of the addresses
        "0x000000000000000000000000000000000000000000000000000000000000000f",
        "0x0000000000000000000000000000000000000000000000000000000000000001",
        "0x0000000000000000000000000000000000000000000000000000000000000001"
      ];

      const get_data = await universalProfile["getData(bytes32[])"](keys);
      
      expect(get_data).to.deep.equal(values);
    });

    // TODO set the permissions for the keymanager to the multisig and dao. maybe vault?

    /*it("Should update the members with necessary permissions",async () => {
      const { universalProfile, multisig, owner, account1, account2 } = await loadFixture(deployRawMultisigKeyManager);

      const keys = [
        "0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3",
        "0xdf30dba06db6a30e65354d9a64c60986" + "00000000000000000000000000000000",
        "0xdf30dba06db6a30e65354d9a64c60986" + "00000000000000000000000000000001",
        "0x4b80742de2bf82acb3630000" + multisig.address.substring(2),
        "0x4b80742de2bf82acb3630000" + owner.address.substring(2),
        "0x47499aa724781173ffff2a8a82c6223b88e1a838d32bb91a9ff9c9c0b8c8759b",
  
        "0x54aef89da199194b126d28036f71291726191dbff7160f9d0986952b17eaedb4",
        "0x54aef89da199194b126d28036f712917" + "00000000000000000000000000000000",
        "0x54aef89da199194b126d28036f712917" + "00000000000000000000000000000001",
        "0x54aef89da199194b126d28036f712917" + "00000000000000000000000000000002",
        "0x4164647265734d756c740000" + owner.address.substring(2),
        "0x4164647265734d756c740000" + account1.address.substring(2),
        "0x4164647265734d756c740000" + account2.address.substring(2)
      ];
      const values = [
        "0x0000000000000000000000000000000000000000000000000000000000000004",
        multisig.address.toLowerCase(),
        owner.address.toLowerCase(),
        "0x0000000000000000000000000000000000000000000000000000000000007fbf",
        "0x0000000000000000000000000000000000000000000000000000000000000001",
        ethers.utils.hexValue(50),
  
        "0x0000000000000000000000000000000000000000000000000000000000000003",
        owner.address.toLowerCase(),
        account1.address.toLowerCase(),
        account2.address.toLowerCase(),
        "0x000000000000000000000000000000000000000000000000000000000000000f",
        "0x0000000000000000000000000000000000000000000000000000000000000001",
        "0x0000000000000000000000000000000000000000000000000000000000000001"
      ];
  
      await universalProfile["setData(bytes32[],bytes[])"](keys, values);
      const get_data = await universalProfile["getData(bytes32[])"](keys);
      
      expect(get_data).to.deep.equal(values);
    });

    it("Should transfer ownership from EOA to key manager", async () => {
      const { universalProfile, keyManager } = await loadFixture(deployMultisigKeyManagerWithMultisigPermissionsSet);

      await universalProfile.transferOwnership(keyManager.address);

      let ABI = ["function claimOwnership()"];
      let iface = new ethers.utils.Interface(ABI);
      await keyManager.execute(iface.encodeFunctionData("claimOwnership"));

      expect(await universalProfile.owner()).to.equal(keyManager.address);
    });

    it("Should be able to add permissions", async () => {
      const { universalProfile, multisig, owner, account1 } = await loadFixture(deployMultisigKeyManagerWithDataSetAndOwnershipTransfered);

      await multisig.connect(owner).addPermissions(
        account1.address, 
        "0x000000000000000000000000000000000000000000000000000000000000000e"
      );

      expect(await universalProfile["getData(bytes32)"]("0x4164647265734d756c740000" + account1.address.substring(2)))
      .to.equal("0x000000000000000000000000000000000000000000000000000000000000000f");
    });

    it("Should not be able to add permissions", async () => {
      const { multisig, account1, account2 } = await loadFixture(deployMultisigKeyManagerWithDataSetAndOwnershipTransfered);

      const add_permission = multisig.connect(account1).addPermissions(
        account2.address, 
        "0x000000000000000000000000000000000000000000000000000000000000000e"
      );

      let ABI = ["error NotAuthorised(address from, string permission)"];
      let errorInterface = new ethers.utils.Interface(ABI);
      const errorContract = new ethers.Contract("LSP6Errors", errorInterface, ethers.provider);
      expect(add_permission).to.revertedWithCustomError(
        errorContract,
        "NotAuthorised"
      );
    });

    it("Should not be able to remove permissions", async () => {
      const { multisig, owner, account1 } = await loadFixture(deployMultisigKeyManagerWithDataSetAndOwnershipTransfered);

      const add_permission = multisig.connect(account1).removePermissions(
        owner.address, 
        "0x000000000000000000000000000000000000000000000000000000000000000e"
      );

      let ABI = ["error NotAuthorised(address from, string permission)"];
      let errorInterface = new ethers.utils.Interface(ABI);
      const errorContract = new ethers.Contract("LSP6Errors", errorInterface, ethers.provider);
      expect(add_permission).to.revertedWithCustomError(
        errorContract,
        "NotAuthorised"
      );
    });

    it("Should be able to propose something for execution", async () => {
      const { universalProfile, keyManager, multisig, owner, account1, account2 } = await loadFixture(deployMultisigKeyManagerWithDataSetAndOwnershipTransfered);

      let ABI = ["function setData(bytes32 dataKey, bytes memory dataValue)"];
      let ERC725Yinterface = new ethers.utils.Interface(ABI);
      const targets = [universalProfile.address];
      const datas = [
        ERC725Yinterface.encodeFunctionData(
          "setData",
          [
            "0x4164647265734d756c740000" + account1.address.substring(2),
            "0x000000000000000000000000000000000000000000000000000000000000000f"
          ]
        )
      ];

      const propose = await multisig.connect(owner).proposeExecution(targets, datas);
      const proposeReturnValue = (await propose.wait(1)).logs[3].data.substring(0, 22);
      
      const keys = [
        proposeReturnValue + "0000c6c66d5a29ded4b70a2bc4d1637290a99598996b",
        proposeReturnValue + "0000a127ec6f6a314082d85a8df20cec2eb66abc0e15"
      ];
      const values = [
        ethers.utils.defaultAbiCoder.encode(["address[]"], [targets]),
        ethers.utils.defaultAbiCoder.encode(["bytes[]"], [datas])
      ];

      expect((await universalProfile["getData(bytes32[])"](keys))).to.be.deep.equal(values);
    });

    it("Should not be able to propose something for execution", async () => {
      const { universalProfile, keyManager, multisig, owner, account1, account2 } = await loadFixture(deployMultisigKeyManagerWithDataSetAndOwnershipTransfered);

      const ABI_SET_DATA = ["function setData(bytes32 dataKey, bytes memory dataValue)"];
      const ERC725Yinterface = new ethers.utils.Interface(ABI_SET_DATA);
      const targets = [universalProfile.address];
      const datas = [
        ERC725Yinterface.encodeFunctionData(
          "setData",
          [
            "0x4164647265734d756c740000" + account1.address.substring(2),
            "0x000000000000000000000000000000000000000000000000000000000000000f"
          ]
        )
      ];

      const propose = multisig.connect(account1).proposeExecution(targets, datas);

      const ABI_ERROR = ["error NotAuthorised(address from, string permission)"];
      const errorInterface = new ethers.utils.Interface(ABI_ERROR);
      const errorContract = new ethers.Contract("LSP6Errors", errorInterface, ethers.provider);

      expect(propose).to.be.revertedWithCustomError(
        errorContract,
        "NotAuthorised"
      );
    });*/

    
    
  });
})