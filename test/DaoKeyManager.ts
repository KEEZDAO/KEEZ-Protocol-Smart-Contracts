import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Deployment testing & Individual contracts method testing", function () {
  async function deployContracts() {

    const [owner, account1, account2, account3, account4, account5, account6] = await ethers.getSigners();

    const UniversalReceiverDelegateUP = await ethers.getContractFactory("UniversalReceiverDelegateUP");
    const universalReceiverDelegateUP = await UniversalReceiverDelegateUP.deploy();

    const UniversalReceiverDelegateVault = await ethers.getContractFactory("UniversalReceiverDelegateVault");
    const universalReceiverDelegateVault = await UniversalReceiverDelegateVault.deploy();

    // TODO give key manager super set data perission.

    const UniversalProfile = await ethers.getContractFactory("UniversalProfile");
    const universalProfile = await UniversalProfile.deploy(owner.address, universalReceiverDelegateUP.address);

    const Vault = await ethers.getContractFactory("Vault");
    const vault = await Vault.deploy(owner.address, universalReceiverDelegateVault.address);

    const KeyManager = await ethers.getContractFactory("KeyManager");
    const keyManager = await KeyManager.deploy(universalProfile.address);

    const DaoPermissions = await ethers.getContractFactory("DaoPermissions");
    const daoPermissions = await DaoPermissions.deploy(universalProfile.address, keyManager.address);

    const DaoDelegates = await ethers.getContractFactory("DaoDelegates");
    const daoDelegates = await DaoDelegates.deploy(universalProfile.address, keyManager.address);

    const DaoProposals = await ethers.getContractFactory("DaoProposals");
    const daoProposals = await DaoProposals.deploy(universalProfile.address, keyManager.address);

    // Initialize the dao with new members.
    await universalProfile.connect(owner).setDaoData(
      ethers.utils.hexlify(ethers.utils.toUtf8Bytes("https://somelink.com/")),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
      [
        owner.address,
        account1.address,
        account2.address
      ],
      [
        "0x00000000000000000000000000000000000000000000000000000000000000ff",
        "0x00000000000000000000000000000000000000000000000000000000000000ff",
        "0x00000000000000000000000000000000000000000000000000000000000000ff"
      ]
    );
  
    // Using initializing methods of the universal profile.
    await universalProfile.giveOwnerPermissionToChangeOwner();
    await universalProfile.setControllerPermissionsForDao(
      daoPermissions.address,
      daoDelegates.address,
      daoProposals.address
    );

    // Giving the ownership of the Universal Profile to the Key Manager.
    await universalProfile.transferOwnership(keyManager.address);
    let ABI = ["function claimOwnership()"];
    let iface = new ethers.utils.Interface(ABI);
    await keyManager.execute(iface.encodeFunctionData("claimOwnership"));

    return {
      universalReceiverDelegateUP,
      universalProfile,
      vault,
      keyManager,
      daoPermissions,
      daoDelegates,
      daoProposals,
      owner,
      account1,
      account2,
      account3,
      account4,
      account5,
      account6
    };
  }

  async function deployContractsAndPropose() {
    const { universalProfile, daoProposals, owner, account1, account2, account3, account4, account5, account6 } = await loadFixture(deployContracts);

    const ABI = ["function setData(bytes32 dataKey, bytes memory dataValue)"];
    const ERC725Yinterface = new ethers.utils.Interface(ABI);
    const payloads = [
      ERC725Yinterface.encodeFunctionData(
        "setData",
        [
          "0x4b80742de2bfb3cc0e490000" + account6.address.substring(2),
          "0x000000000000000000000000000000000000000000000000000000000000ffff"
        ]
      )
    ];

    const create_proposal = await daoProposals.connect(owner).createProposal(
      "Som random title",
      "https://somerandomlink.sahs",
      ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
      payloads,
      ethers.utils.hexZeroPad(ethers.utils.hexValue(2), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(1), 32)
    );

    const proposalSignature = (await create_proposal.wait(1)).logs[9].data.substring(0, 22);

    return {
      universalProfile,
      daoProposals,
      proposalSignature,
      payloads,
      owner,
      account1,
      account2,
      account3,
      account4,
      account5,
      account6
    }
  }

  describe("Universal profile deployment", () => {

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

    it("Should set dao permissions correctly", async () => {
      const { universalProfile, owner, account1, account2 } = await loadFixture(deployContracts);

      const keys = [
        // metadata of the dao
        "0x529fc5ec0943a0370fe51d4dec0787294933572592c61b103d9e170cb15e8e79",
        "0xbc776f168e7b9c60bb2a7180950facd372cd90c841732d963c31a93ff9f8c127",
        "0xf89f507ecd9cb7646ce1514ec6ab90d695dac9314c3771f451fd90148a3335a9",
        "0x799787138cc40d7a47af8e69bdea98db14e1ead8227cef96814fa51751e25c76",
        "0xd3cf4cd71858ea36c3f5ce43955db04cbe9e1f42a2c7795c25c1d430c9bb280a",
        "0xb207580c05383177027a90d6c298046d3d60dfa05a32b0bb48ea9015e11a3424",
        // array length and array elements
        "0xf7f9c7410dd493d79ebdaee15bbc77fd163bd488f54107d1be6ed34b1e099004",
        "0xf7f9c7410dd493d79ebdaee15bbc77fd" + "00000000000000000000000000000000",
        "0xf7f9c7410dd493d79ebdaee15bbc77fd" + "00000000000000000000000000000001",
        "0xf7f9c7410dd493d79ebdaee15bbc77fd" + "00000000000000000000000000000002",
        // mapping of the addresses
        "0xf7f9c7410dd493d79ebd0000" + owner.address.substring(2),
        "0xf7f9c7410dd493d79ebd0000" + account1.address.substring(2),
        "0xf7f9c7410dd493d79ebd0000" + account2.address.substring(2),
        // permissions of the addresses
        "0x4b80742de2bfb3cc0e490000" + owner.address.substring(2),
        "0x4b80742de2bfb3cc0e490000" + account1.address.substring(2),
        "0x4b80742de2bfb3cc0e490000" + account2.address.substring(2)
      ];
      const values = [
        // metadata of the dao
        ethers.utils.hexlify(ethers.utils.toUtf8Bytes("https://somelink.com/")),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
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
        "0x00000000000000000000000000000000000000000000000000000000000000ff",
        "0x00000000000000000000000000000000000000000000000000000000000000ff",
        "0x00000000000000000000000000000000000000000000000000000000000000ff"
      ];

      const get_data = await universalProfile["getData(bytes32[])"](keys);
      
      expect(get_data).to.deep.equal(values);
    });

    it("Should update the owner permissions, owner should have change owner permission.",async () => {
      const { universalProfile, owner } = await loadFixture(deployContracts);

      const keys = [
        "0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3",
        "0xdf30dba06db6a30e65354d9a64c60986" + "00000000000000000000000000000000",
        "0x4b80742de2bf82acb3630000" + owner.address.substring(2)
      ];
      const values = [
        "0x0000000000000000000000000000000000000000000000000000000000000004",
        owner.address.toLowerCase(),
        "0x0000000000000000000000000000000000000000000000000000000000000001"
      ];
  
      const get_data = await universalProfile["getData(bytes32[])"](keys);
      
      expect(get_data).to.deep.equal(values);
    });

    it("Should update the dao controller permissions",async () => {
      const { universalProfile, daoPermissions, daoDelegates, daoProposals } = await loadFixture(deployContracts);

      const keys = [
        "0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3",
        "0xdf30dba06db6a30e65354d9a64c60986" + "00000000000000000000000000000001",
        "0xdf30dba06db6a30e65354d9a64c60986" + "00000000000000000000000000000002",
        "0xdf30dba06db6a30e65354d9a64c60986" + "00000000000000000000000000000003",
        "0x4b80742de2bf82acb3630000" + daoPermissions.address.substring(2),
        "0x4b80742de2bf82acb3630000" + daoDelegates.address.substring(2),
        "0x4b80742de2bf82acb3630000" + daoProposals.address.substring(2)
      ];
      const values = [
        "0x0000000000000000000000000000000000000000000000000000000000000004",
        daoPermissions.address.toLowerCase(),
        daoDelegates.address.toLowerCase(),
        daoProposals.address.toLowerCase(),
        "0x0000000000000000000000000000000000000000000000000000000000007fbf",
        "0x0000000000000000000000000000000000000000000000000000000000007fbf",
        "0x0000000000000000000000000000000000000000000000000000000000007fbf"
      ];

      const get_data = await universalProfile["getData(bytes32[])"](keys);
      
      expect(get_data).to.deep.equal(values);
    });

    it("Should transfer ownership from EOA to key manager", async () => {
      const { universalProfile, keyManager } = await loadFixture(deployContracts);

      expect(await universalProfile.owner()).to.equal(keyManager.address);
    });
  });

  describe("Dao permission methods", () => {

    it("Should be able to add permissions", async () => {
      const { universalProfile, daoPermissions, owner, account3 } = await loadFixture(deployContracts);

      await daoPermissions.connect(owner).addPermissions(
        account3.address, 
        "0x000000000000000000000000000000000000000000000000000000000000000e"
      );

      const keys = [
        "0x4b80742de2bfb3cc0e490000" + account3.address.substring(2),
        "0xf7f9c7410dd493d79ebdaee15bbc77fd163bd488f54107d1be6ed34b1e099004",
        "0xf7f9c7410dd493d79ebdaee15bbc77fd00000000000000000000000000000003",
        "0xf7f9c7410dd493d79ebd0000" + account3.address.substring(2)
      ];
      const values = [
        "0x000000000000000000000000000000000000000000000000000000000000000e",
        "0x0000000000000000000000000000000000000000000000000000000000000004",
        account3.address.toLowerCase(),
        "0x0000000000000000000000000000000000000000000000000000000000000003"
      ];

      const actualData = await universalProfile["getData(bytes32[])"](keys);

      expect(actualData).to.deep.equal(values);
    });

    it("Should not be able to add permissions", async () => {
      const { daoPermissions, account2, account3 } = await loadFixture(deployContracts);

      const add_permission = daoPermissions.connect(account3).addPermissions(
        account2.address, 
        "0x0000000000000000000000000000000000000000000000000000000000000010"
      );

      let ABI = ["error NotAuthorised(address from, string permission)"];
      let errorInterface = new ethers.utils.Interface(ABI);
      const errorContract = new ethers.Contract("LSP6Errors", errorInterface, ethers.provider);

      await expect(add_permission).to.revertedWithCustomError(
        errorContract,
        "NotAuthorised"
      ).withArgs(account3.address, "ADD_PERMISSION");
    });

    it("Should be able to remove permissions", async () => {
      const { universalProfile, daoPermissions, owner, account1, account2 } = await loadFixture(deployContracts);

      // remove all permissions
      await daoPermissions.connect(owner).removePermissions(
        account1.address, 
        "0x00000000000000000000000000000000000000000000000000000000000000ff" // 1111 1111
      );

      // remove multiple permissions
      await daoPermissions.connect(owner).removePermissions(
        account2.address, 
        "0x0000000000000000000000000000000000000000000000000000000000000003" // 0000 0011
      );

      const keys = [
        // modified users permissions
        "0x4b80742de2bfb3cc0e490000" + account1.address.substring(2),
        "0x4b80742de2bfb3cc0e490000" + account2.address.substring(2),
        // dao user array length
        "0xf7f9c7410dd493d79ebdaee15bbc77fd163bd488f54107d1be6ed34b1e099004",
        // dao user indexes
        "0xf7f9c7410dd493d79ebdaee15bbc77fd00000000000000000000000000000001",
        "0xf7f9c7410dd493d79ebdaee15bbc77fd00000000000000000000000000000002",
        // dao users mappings
        "0xf7f9c7410dd493d79ebd0000" + account1.address.substring(2),
        "0xf7f9c7410dd493d79ebd0000" + account2.address.substring(2)
      ];
      const values = [
        // modified users permissions
        "0x",
        "0x00000000000000000000000000000000000000000000000000000000000000fc",
        // dao user array length
        "0x0000000000000000000000000000000000000000000000000000000000000002",
        // dao user indexes
        account2.address.toLowerCase(),
        "0x",
        // dao users mappings
        "0x",
        "0x0000000000000000000000000000000000000000000000000000000000000001"
      ];

      expect(await universalProfile["getData(bytes32[])"](keys))
      .to.deep.equal(values);
    });

    it("Should not be able to remove permissions", async () => {
      const { daoPermissions, account2, account3 } = await loadFixture(deployContracts);

      const remove_permission = daoPermissions.connect(account3).removePermissions(
        account2.address, 
        "0x000000000000000000000000000000000000000000000000000000000000000f"
      );

      let ABI = ["error NotAuthorised(address from, string permission)"];
      let errorInterface = new ethers.utils.Interface(ABI);
      const errorContract = new ethers.Contract("LSP6Errors", errorInterface, ethers.provider);
      await expect(remove_permission).to.revertedWithCustomError(
        errorContract,
        "NotAuthorised"
      ).withArgs(account3.address, "REMOVE_PERMISSION");
    });
  });

  describe("Dao claiming methods", () => {

    it("Should be able to claim permission from an authorized address", async () => {
      const { universalProfile, daoPermissions, owner, account3 } = await loadFixture(deployContracts);

      const ownerHash = await daoPermissions.getNewPermissionHash(
        owner.address,
        account3.address,
        "0x0000000000000000000000000000000000000000000000000000000000000001"
      );

      const ownerSig = await owner.signMessage(ethers.utils.arrayify(ownerHash));

      await daoPermissions.connect(account3).claimPermission(
        owner.address,
        "0x0000000000000000000000000000000000000000000000000000000000000001",
        ownerSig
      );

      const key = "0x4b80742de2bfb3cc0e490000" + account3.address.substring(2);
      const value = "0x0000000000000000000000000000000000000000000000000000000000000001"

      expect(await universalProfile["getData(bytes32)"](key)).to.equal(value);
    });

    it("Should not be able to claim twice from an authorized address", async () => {
      const { daoPermissions, owner, account3 } = await loadFixture(deployContracts);

      const ownerHash = await daoPermissions.getNewPermissionHash(
        owner.address,
        account3.address,
        "0x0000000000000000000000000000000000000000000000000000000000000001"
      );

      const ownerSig = await owner.signMessage(ethers.utils.arrayify(ownerHash));

      await daoPermissions.connect(account3).claimPermission(
        owner.address,
        "0x0000000000000000000000000000000000000000000000000000000000000001",
        ownerSig
      );

      const secondClaim =  daoPermissions.connect(account3).claimPermission(
        owner.address,
        "0x0000000000000000000000000000000000000000000000000000000000000001",
        ownerSig
      );

      let ABI = ["error NotAuthorised(address from, string permission)"];
      let errorInterface = new ethers.utils.Interface(ABI);
      const errorContract = new ethers.Contract("LSP6Errors", errorInterface, ethers.provider);
      
      expect(secondClaim).to.revertedWithCustomError(
        errorContract,
        "NotAuthorised"
      );
    });

    it("Should not be able to claim from an unauthorized address", async () => {
      const { daoPermissions, account3, account4 } = await loadFixture(deployContracts);

      const acc3Hash = await daoPermissions.getNewPermissionHash(
        account3.address,
        account4.address,
        "0x0000000000000000000000000000000000000000000000000000000000000001"
      );

      const ownerSig = await account3.signMessage(ethers.utils.arrayify(acc3Hash));

      const claimigTrx = daoPermissions.connect(account4).claimPermission(
        account3.address,
        "0x0000000000000000000000000000000000000000000000000000000000000001",
        ownerSig
      );

      let ABI = ["error NotAuthorised(address from, string permission)"];
      let errorInterface = new ethers.utils.Interface(ABI);
      const errorContract = new ethers.Contract("LSP6Errors", errorInterface, ethers.provider);
      
      expect(claimigTrx).to.revertedWithCustomError(
        errorContract,
        "NotAuthorised"
      ).withArgs(account3.address, "ADD_PERMISSIONS");
    });
  });

  describe("Dao delegate methods", () => {

    it("Should delegate the vote", async () => {
      const { universalProfile, daoDelegates, owner, account1 } = await loadFixture(deployContracts);

      await daoDelegates.connect(owner).delegate(account1.address);

      const keys = [
        "0x0a30e74a6c7868e400140000" + owner.address.substring(2),
        "0x92a4ebfa1896d9ad8b430000" + account1.address.substring(2)
      ];
      const values = [
        account1.address.toLowerCase(),
        (new ethers.utils.AbiCoder()).encode([ "address[]" ], [ [owner.address] ])
      ];

      const get_data = await universalProfile["getData(bytes32[])"](keys);

      expect(get_data).to.deep.equal(values);
    });

    it("Should delegate 2 votes", async () => {
      const { universalProfile, daoPermissions, daoDelegates, owner, account1, account2 } = await loadFixture(deployContracts);

      await daoPermissions.connect(owner).addPermissions(
        account2.address,
        "0x0000000000000000000000000000000000000000000000000000000000000010"
      );
      await daoDelegates.connect(owner).delegate(account2.address);
      await daoDelegates.connect(account1).delegate(account2.address);
  
      const keys = [
        "0x0a30e74a6c7868e400140000" + owner.address.substring(2),
        "0x0a30e74a6c7868e400140000" + account1.address.substring(2),
        "0x92a4ebfa1896d9ad8b430000" + account2.address.substring(2)
      ];
      const values = [
        account2.address.toLowerCase(),
        account2.address.toLowerCase(),
        (new ethers.utils.AbiCoder()).encode([ "address[]" ], [ [owner.address, account1.address] ])
      ];

      const get_data = await universalProfile["getData(bytes32[])"](keys);

      expect(get_data).to.deep.equal(values);
    });

    it("Should be able to change the delegate (1 delegate in both arrays)", async () => {
      const { universalProfile, daoPermissions, daoDelegates, owner, account1, account2 } = await loadFixture(deployContracts);

      await daoPermissions.connect(owner).addPermissions(
        account2.address,
        "0x0000000000000000000000000000000000000000000000000000000000000010"
      );
      await daoDelegates.connect(owner).delegate(account1.address);
      await daoDelegates.connect(owner).changeDelegate(account2.address);

      const keys = [
        "0x0a30e74a6c7868e400140000" + owner.address.substring(2),
        "0x92a4ebfa1896d9ad8b430000" + account2.address.substring(2),
        "0x92a4ebfa1896d9ad8b430000" + account1.address.substring(2)
      ];
      const values = [
        account2.address.toLowerCase(),
        (new ethers.utils.AbiCoder()).encode([ "address[]" ], [ [owner.address] ]),
        "0x"
      ];

      const get_data = await universalProfile["getData(bytes32[])"](keys);

      expect(get_data).to.deep.equal(values);
    });

    it("Should be able to change the delegate (2 delegates in first array, 1 delegate in second array)", async () => {
      const { universalProfile, daoPermissions, daoDelegates, owner, account1, account2, account3 } = await loadFixture(deployContracts);

      await daoPermissions.connect(owner).addPermissions(
        account2.address,
        "0x0000000000000000000000000000000000000000000000000000000000000010"
      );
      await daoPermissions.connect(owner).addPermissions(
        account3.address,
        "0x0000000000000000000000000000000000000000000000000000000000000010"
      );
      await daoDelegates.connect(owner).delegate(account2.address);
      await daoDelegates.connect(account1).delegate(account2.address);
      await daoDelegates.connect(owner).changeDelegate(account3.address);

      const keys = [
        "0x0a30e74a6c7868e400140000" + owner.address.substring(2),
        "0x0a30e74a6c7868e400140000" + account1.address.substring(2),
        "0x92a4ebfa1896d9ad8b430000" + account2.address.substring(2),
        "0x92a4ebfa1896d9ad8b430000" + account3.address.substring(2)
      ];
      const values = [
        account3.address.toLowerCase(),
        account2.address.toLowerCase(),
        (new ethers.utils.AbiCoder()).encode([ "address[]" ], [ [account1.address] ]),
        (new ethers.utils.AbiCoder()).encode([ "address[]" ], [ [owner.address] ])
      ];

      const get_data = await universalProfile["getData(bytes32[])"](keys);

      expect(get_data).to.deep.equal(values);
    });

    it("Should be able to change the delegate (2 delegates in both arrays)", async () => {
      const {
        universalProfile,
        daoPermissions,
        daoDelegates,
        owner,
        account1,
        account2,
        account3,
        account4,
        account5
      } = await loadFixture(deployContracts);

      await daoPermissions.connect(owner).addPermissions(
        account4.address,
        "0x000000000000000000000000000000000000000000000000000000000000007f"
      );
      await daoDelegates.connect(owner).delegate(account4.address);
      await daoDelegates.connect(account1).delegate(account4.address);

      await daoPermissions.connect(owner).addPermissions(
        account5.address,
        "0x000000000000000000000000000000000000000000000000000000000000007f"
      );
      await daoPermissions.connect(owner).addPermissions(
        account3.address,
        "0x000000000000000000000000000000000000000000000000000000000000007f"
      );
      await daoDelegates.connect(account2).delegate(account5.address);
      await daoDelegates.connect(account3).delegate(account5.address);

      const keys1 = [
        "0x0a30e74a6c7868e400140000" + owner.address.substring(2),
        "0x0a30e74a6c7868e400140000" + account1.address.substring(2),
        "0x0a30e74a6c7868e400140000" + account2.address.substring(2),
        "0x0a30e74a6c7868e400140000" + account3.address.substring(2),
        "0x92a4ebfa1896d9ad8b430000" + account4.address.substring(2),
        "0x92a4ebfa1896d9ad8b430000" + account5.address.substring(2)
      ];
      const values1 = [
        account4.address.toLowerCase(),
        account4.address.toLowerCase(),
        account5.address.toLowerCase(),
        account5.address.toLowerCase(),
        (new ethers.utils.AbiCoder()).encode([ "address[]" ], [ [owner.address, account1.address] ]),
        (new ethers.utils.AbiCoder()).encode([ "address[]" ], [ [account2.address, account3.address] ])
      ];

      const get_data1 = await universalProfile["getData(bytes32[])"](keys1);

      expect(get_data1).to.deep.equal(values1);

      await daoDelegates.connect(owner).changeDelegate(account5.address);

      const keys2 = [
        "0x0a30e74a6c7868e400140000" + owner.address.substring(2),
        "0x0a30e74a6c7868e400140000" + account1.address.substring(2),
        "0x0a30e74a6c7868e400140000" + account2.address.substring(2),
        "0x0a30e74a6c7868e400140000" + account3.address.substring(2),
        "0x92a4ebfa1896d9ad8b430000" + account4.address.substring(2),
        "0x92a4ebfa1896d9ad8b430000" + account5.address.substring(2)
      ];
      const values2 = [
        account5.address.toLowerCase(),
        account4.address.toLowerCase(),
        account5.address.toLowerCase(),
        account5.address.toLowerCase(),
        (new ethers.utils.AbiCoder()).encode([ "address[]" ], [ [account1.address] ]),
        (new ethers.utils.AbiCoder()).encode([ "address[]" ], [ [account2.address, account3.address, owner.address] ])
      ];

      const get_data2 = await universalProfile["getData(bytes32[])"](keys2);

      expect(get_data2).to.deep.equal(values2);
    });

    it("Should undelegate the vote", async () => {
      const { universalProfile, daoDelegates, owner, account1 } = await loadFixture(deployContracts);

      await daoDelegates.connect(owner).delegate(account1.address);
      const keys1 = [
        "0x0a30e74a6c7868e400140000" + owner.address.substring(2),
        "0x92a4ebfa1896d9ad8b430000" + account1.address.substring(2)
      ];
      const values1 = [
        account1.address.toLowerCase(),
        (new ethers.utils.AbiCoder()).encode([ "address[]" ], [ [owner.address] ])
      ];

      const get_data1 = await universalProfile["getData(bytes32[])"](keys1);

      expect(get_data1).to.deep.equal(values1);

      await daoDelegates.connect(owner).undelegate();
      const keys2 = [
        "0x0a30e74a6c7868e400140000" + owner.address.substring(2),
        "0x92a4ebfa1896d9ad8b430000" + account1.address.substring(2)
      ];
      const values2 = [
        "0x",
        "0x"
      ];

      const get_data2 = await universalProfile["getData(bytes32[])"](keys2);

      expect(get_data2).to.deep.equal(values2);
    });

  });

  describe("Dao proposals methods", () => {

    it("Should not be able to make a proposal", async () => {
      const { daoProposals, account6 } = await loadFixture(deployContracts);
  
      const create_proposal = daoProposals.connect(account6).createProposal(
        "Som random title",
        "https://somerandomlink.sahs",
        ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
        [],
        ethers.utils.hexZeroPad(ethers.utils.hexValue(2), 32),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(1), 32)
      );

      let ABI = ["error NotAuthorised(address from, string permission)"];
      let errorInterface = new ethers.utils.Interface(ABI);
      const errorContract = new ethers.Contract("LSP6Errors", errorInterface, ethers.provider);

      await expect(create_proposal).to.be.revertedWithCustomError(
        errorContract,
        "NotAuthorised"
      ).withArgs(account6.address, "PROPOSE");
    });

    it("Should be able to make a proposal", async () => {
      const { universalProfile, proposalSignature, payloads } = await loadFixture(deployContractsAndPropose);

      const keys = [
        proposalSignature + "00004a8279d372333473468a5a28870c140a7941f668",
        proposalSignature + "0000cc713dffc839645a02779745d6e8e8cca753795c",
        proposalSignature + "00006ebe389303905e56ea48aecac1536207791d0e67",
        proposalSignature + "0000164526a330a273b37abc4c89336a3042182a3910",
        proposalSignature + "0000922cb700268d68a7160e60fe26870af11cd98aaa",
        proposalSignature + "0000e5dd8acc7154a678a0a3fa3fe2d65b8700bf702c",
        proposalSignature + "00002d53f22395ee464559c1d5b27661145933a15e8f"
      ];
      const values = [
        ethers.utils.hexlify(ethers.utils.toUtf8Bytes("https://somerandomlink.sahs")),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
        ethers.utils.defaultAbiCoder.encode(["bytes[]"], [payloads]),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(2), 32),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(1), 32)
      ];

      const get_data = await universalProfile["getData(bytes32[])"](keys);

      expect(get_data).to.deep.equal(values);
    });

    it("Should not be able to execute without the voting phases passed", async () => {
      const { daoProposals, proposalSignature, owner } = await loadFixture(deployContractsAndPropose);

      let ABI = ["error IndexedError(string contractName, bytes1 errorNumber)"];
      let errorInterface = new ethers.utils.Interface(ABI);
      const errorContract = new ethers.Contract("LSP6Errors", errorInterface, ethers.provider);

      const register_users = daoProposals.connect(owner).registerVotes(
        proposalSignature,
        [],
        [],
        []
      );

      await expect(register_users).to.be.revertedWithCustomError(
        errorContract,
        "IndexedError"
      ).withArgs("DaoProposals", "0x06");
      
      const execute_proposal = daoProposals.connect(owner).executeProposal(
        proposalSignature
      );

      await expect(execute_proposal).to.be.revertedWithCustomError(
        errorContract,
        "IndexedError"
      ).withArgs("DaoProposals", "0x08");
    });

    it("Should be able to execute with 3 votes", async () => {
      const { universalProfile, daoProposals, proposalSignature, payloads, owner, account1, account2, account6 } = await loadFixture(deployContractsAndPropose);

      const arrayOfChoices = [
        ethers.utils.hexZeroPad(ethers.utils.hexValue(1), 32),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(1), 32),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(1), 32)
      ];

      const hashOwner = await daoProposals.getProposalHash(
        owner.address,
        proposalSignature,
        arrayOfChoices[0]
      );
      const hashAcc1  = await daoProposals.getProposalHash(
        account1.address,
        proposalSignature,
        arrayOfChoices[1]
      );
      const hashAcc2  = await daoProposals.getProposalHash(
        account2.address,
        proposalSignature,
        arrayOfChoices[2]
      );

      const signatures = [
        await owner.signMessage(ethers.utils.arrayify(hashOwner)),
        await account1.signMessage(ethers.utils.arrayify(hashAcc1)),
        await account2.signMessage(ethers.utils.arrayify(hashAcc2))
      ];

      /*
      [
        user1Address,
        user2Address,
        ...
      ]
      [
        user1Sig,
        user2Sig,
        ...
      ]
      [
        user1Choices,
        user2Choices,
        ...
      ]
      */

      await ethers.provider.send('evm_increaseTime', [120]); 
      await ethers.provider.send('evm_mine', []);

      await daoProposals.connect(owner).registerVotes(
        proposalSignature,
        signatures,
        [
          owner.address,
          account1.address,
          account2.address
        ],
        arrayOfChoices
      );

      await ethers.provider.send('evm_increaseTime', [120 + 60 * 60 * 24]); 
      await ethers.provider.send('evm_mine', []);
      
      await daoProposals.connect(owner).executeProposal(
        proposalSignature
      );
      
      const getUserUpdatedPermissions = await universalProfile["getData(bytes32)"](
        "0x4b80742de2bfb3cc0e490000" + account6.address.substring(2)
      );

      expect(getUserUpdatedPermissions).to.be.equal(
        "0x000000000000000000000000000000000000000000000000000000000000ffff"
      );
    });

  });

});