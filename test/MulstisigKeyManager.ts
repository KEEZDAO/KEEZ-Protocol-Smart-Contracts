import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Deployment testing & Individual contracts method testing", function () {
  async function deployContracts() {

    const [owner, account1, account2, account3, account4] = await ethers.getSigners();

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
      
    // Initialize the multisig with new members.
    await universalProfile.connect(owner).setMultisigData(
      ethers.utils.hexlify(ethers.utils.toUtf8Bytes("https://somelink.com/")),
      ethers.utils.hexValue(50),
      [
        owner.address,
        account1.address,
        account2.address
      ],
      [
        "0x000000000000000000000000000000000000000000000000000000000000001f",
        "0x000000000000000000000000000000000000000000000000000000000000001f",
        "0x000000000000000000000000000000000000000000000000000000000000000f"
      ]
    );
  
    // Using initializing methods of the universal profile.
    await universalProfile.giveOwnerPermissionToChangeOwner();
    await universalProfile.setControllerPermissionsForMultisig(multisig.address);

    // Giving the ownership of the Universal Profile to the Key Manager.
    await universalProfile.transferOwnership(keyManager.address);
    let ABI = ["function claimOwnership()"];
    let iface = new ethers.utils.Interface(ABI);
    await keyManager.execute(iface.encodeFunctionData("claimOwnership"));

    return { universalReceiverDelegateUP, universalProfile, vault, keyManager, multisig, dao, owner, account1, account2, account3, account4 };
  }
  async function deployContractsAndProposeExecution() {
    const { universalProfile, multisig, owner, account1, account2, account3, account4 } = await loadFixture(deployContracts);

    let ABI = ["function setData(bytes32 dataKey, bytes memory dataValue)"];
    let ERC725Yinterface = new ethers.utils.Interface(ABI);
    const payloads = [
      ERC725Yinterface.encodeFunctionData(
        "setData",
        [
          "0x4164647265734d756c740000" + account3.address.substring(2),
          "0x0000000000000000000000000000000000000000000000000000000000000fff"
        ]
      )
    ];

    const propose = await multisig.connect(owner).proposeExecution(payloads);
    const proposalSignature = (await propose.wait(1)).logs[2].data.substring(0, 22);

    return { universalProfile, multisig, owner, account1, account2, account3, account4, proposalSignature };
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

    it("Should set multisig permissions correctly", async () => {
      const { universalProfile, owner, account1, account2 } = await loadFixture(deployContracts);

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
        "0x000000000000000000000000000000000000000000000000000000000000001f",
        "0x000000000000000000000000000000000000000000000000000000000000001f",
        "0x000000000000000000000000000000000000000000000000000000000000000f"
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
        "0x0000000000000000000000000000000000000000000000000000000000000002",
        owner.address.toLowerCase(),
        "0x0000000000000000000000000000000000000000000000000000000000000001"
      ];
  
      const get_data = await universalProfile["getData(bytes32[])"](keys);
      
      expect(get_data).to.deep.equal(values);
    });

    it("Should update the multisig controller permissions",async () => {
      const { universalProfile, multisig } = await loadFixture(deployContracts);

      const keys = [
        "0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3",
        "0xdf30dba06db6a30e65354d9a64c60986" + "00000000000000000000000000000001",
        "0x4b80742de2bf82acb3630000" + multisig.address.substring(2)
      ];
      const values = [
        "0x0000000000000000000000000000000000000000000000000000000000000002",
        multisig.address.toLowerCase(),
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

  describe("Multisig permission methods", () => {

    it("Should be able to add permissions", async () => {
      const { universalProfile, multisig, owner, account3 } = await loadFixture(deployContracts);

      await multisig.connect(owner).addPermissions(
        account3.address, 
        "0x000000000000000000000000000000000000000000000000000000000000000e"
      );
      const actualData = await universalProfile["getData(bytes32)"]("0x4164647265734d756c740000" + account3.address.substring(2));
      const expectedData = "0x000000000000000000000000000000000000000000000000000000000000000e";

      expect(actualData).to.equal(expectedData);
    });

    it("Should not be able to add permissions", async () => {
      const { multisig, account2, account3 } = await loadFixture(deployContracts);

      const add_permission = multisig.connect(account3).addPermissions(
        account2.address, 
        "0x0000000000000000000000000000000000000000000000000000000000000010"
      );

      let ABI = ["error NotAuthorised(address from, string permission)"];
      let errorInterface = new ethers.utils.Interface(ABI);
      const errorContract = new ethers.Contract("LSP6Errors", errorInterface, ethers.provider);

      expect(add_permission).to.revertedWithCustomError(
        errorContract,
        "NotAuthorised"
      );
    });

    it("Should be able to remove permissions", async () => {
      const { universalProfile, multisig, owner, account1, account2 } = await loadFixture(deployContracts);

      // remove all permissions
      await multisig.connect(owner).removePermissions(
        account1.address, 
        "0x000000000000000000000000000000000000000000000000000000000000001f" // 0001 1111
      );

      // remove multiple permissions
      await multisig.connect(owner).removePermissions(
        account2.address, 
        "0x0000000000000000000000000000000000000000000000000000000000000003" // 0000 0011
      );

      const keys = [
        // modified users permissions
        "0x4164647265734d756c740000" + account1.address.substring(2),
        "0x4164647265734d756c740000" + account2.address.substring(2),
        // multisig user array length
        "0x54aef89da199194b126d28036f71291726191dbff7160f9d0986952b17eaedb4",
        // multisig user indexes
        "0x54aef89da199194b126d28036f71291700000000000000000000000000000001",
        "0x54aef89da199194b126d28036f71291700000000000000000000000000000002",
        // multisig users mappings
        "0x54aef89da199194b126d0000" + account1.address.substring(2),
        "0x54aef89da199194b126d0000" + account2.address.substring(2)
      ];
      const values = [
        // modified users permissions
        "0x",
        "0x000000000000000000000000000000000000000000000000000000000000000c",
        // multisig user array length
        "0x0000000000000000000000000000000000000000000000000000000000000002",
        // multisig user indexes
        account2.address.toLowerCase(),
        "0x",
        // multisig users mappings
        "0x",
        "0x0000000000000000000000000000000000000000000000000000000000000001"
      ];

      expect(await universalProfile["getData(bytes32[])"](keys))
      .to.deep.equal(values);
    });

    it("Should not be able to remove permissions", async () => {
      const { multisig, account2, account3 } = await loadFixture(deployContracts);

      const remove_permission = multisig.connect(account3).removePermissions(
        account2.address, 
        "0x000000000000000000000000000000000000000000000000000000000000000f"
      );

      let ABI = ["error NotAuthorised(address from, string permission)"];
      let errorInterface = new ethers.utils.Interface(ABI);
      const errorContract = new ethers.Contract("LSP6Errors", errorInterface, ethers.provider);
      expect(remove_permission).to.revertedWithCustomError(
        errorContract,
        "NotAuthorised"
      );
    });
  });

  describe("Multisg claiming methods", () => {
    it("Should be able to claim permission from an authorized address", async () => {
      const { universalProfile, multisig, owner, account3 } = await loadFixture(deployContracts);

      const ownerHash = await multisig.getNewPermissionHash(
        owner.address,
        account3.address,
        "0x0000000000000000000000000000000000000000000000000000000000000001"
      );

      const ownerSig = await owner.signMessage(ethers.utils.arrayify(ownerHash));

      await multisig.connect(account3).claimPermission(
        owner.address,
        "0x0000000000000000000000000000000000000000000000000000000000000001",
        ownerSig
      );

      const key = "0x4164647265734d756c740000" + account3.address.substring(2);
      const value = "0x0000000000000000000000000000000000000000000000000000000000000001"

      expect(await universalProfile["getData(bytes32)"](key)).to.equal(value);
    });

    it("Should not be able to claim twice from an authorized address", async () => {
      const { multisig, owner, account3 } = await loadFixture(deployContracts);

      const ownerHash = await multisig.getNewPermissionHash(
        owner.address,
        account3.address,
        "0x0000000000000000000000000000000000000000000000000000000000000001"
      );

      const ownerSig = await owner.signMessage(ethers.utils.arrayify(ownerHash));

      await multisig.connect(account3).claimPermission(
        owner.address,
        "0x0000000000000000000000000000000000000000000000000000000000000001",
        ownerSig
      );

      const secondClaim =  multisig.connect(account3).claimPermission(
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
      const { multisig, account3, account4 } = await loadFixture(deployContracts);

      const acc3Hash = await multisig.getNewPermissionHash(
        account3.address,
        account4.address,
        "0x0000000000000000000000000000000000000000000000000000000000000001"
      );

      const ownerSig = await account3.signMessage(ethers.utils.arrayify(acc3Hash));

      const claimigTrx = multisig.connect(account4).claimPermission(
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
      );
    });
  });

  describe("Multisig execute methods", () => {

    it("Should be able to propose something for execution", async () => {
      const { universalProfile, multisig, owner, account3 } = await loadFixture(deployContracts);

      let ABI = ["function setData(bytes32 dataKey, bytes memory dataValue)"];
      let ERC725Yinterface = new ethers.utils.Interface(ABI);
      const payloads = [
        ERC725Yinterface.encodeFunctionData(
          "setData",
          [
            "0x4164647265734d756c740000" + account3.address.substring(2),
            "0x0000000000000000000000000000000000000000000000000000000000000003"
          ]
        )
      ];

      const propose = await multisig.connect(owner).proposeExecution(payloads);
      const proposalSignature = (await propose.wait(1)).logs[2].data.substring(0, 22);
      
      const key = proposalSignature + "0000870a9bfe5ccee436bab5b4cfd8215400bb038e8e";
      const value = ethers.utils.defaultAbiCoder.encode(["bytes[]"], [payloads]);

      expect(await universalProfile["getData(bytes32)"](key)).to.be.equal(value);
    });

    it("Should not be able to propose something for execution", async () => {
      const { universalProfile, multisig, account3 } = await loadFixture(deployContracts);

      const ABI_SET_DATA = ["function setData(bytes32 dataKey, bytes memory dataValue)"];
      const ERC725Yinterface = new ethers.utils.Interface(ABI_SET_DATA);
      const payloads = [
        ERC725Yinterface.encodeFunctionData(
          "setData",
          [
            "0x4164647265734d756c740000" + account3.address.substring(2),
            "0x0000000000000000000000000000000000000000000000000000000000000003"
          ]
        )
      ];

      const propose = multisig.connect(account3).proposeExecution(payloads);

      const ABI_ERROR = ["error NotAuthorised(address from, string permission)"];
      const errorInterface = new ethers.utils.Interface(ABI_ERROR);
      const errorContract = new ethers.Contract("LSP6Errors", errorInterface, ethers.provider);

      expect(propose).to.be.revertedWithCustomError(
        errorContract,
        "NotAuthorised"
      );
    });

    it("Should not be able to execute 0%", async () => {
      const { multisig, owner, account1, account2, proposalSignature } = await loadFixture(deployContractsAndProposeExecution);

      const hashOwner = await multisig.getProposalHash(owner.address, proposalSignature, false);
      const hashAcc1  = await multisig.getProposalHash(account1.address, proposalSignature, false);
      const hashAcc2  = await multisig.getProposalHash(account2.address, proposalSignature, false);

      const signatures = [
        await owner.signMessage(ethers.utils.arrayify(hashOwner)),
        await account1.signMessage(ethers.utils.arrayify(hashAcc1)),
        await account2.signMessage(ethers.utils.arrayify(hashAcc2))
      ];

      const execute = multisig.connect(owner).execute(
        proposalSignature,
        signatures,
        [
          owner.address,
          account1.address,
          account2.address
        ]
      );

      const ABI_ERROR = ["error IndexedError(string contractName, bytes1 errorNumber)"];
      const errorInterface = new ethers.utils.Interface(ABI_ERROR);
      const errorContract = new ethers.Contract("Errors", errorInterface, ethers.provider);

      expect(execute).to.revertedWithCustomError(
        errorContract,
        "IndexedError"
      );
    });

    it("Should not be able to execute 33%", async () => {
      const { multisig, owner, account1, account2, proposalSignature } = await loadFixture(deployContractsAndProposeExecution);

      const hashOwner = await multisig.getProposalHash(owner.address, proposalSignature, true);
      const hashAcc1  = await multisig.getProposalHash(account1.address, proposalSignature, false);
      const hashAcc2  = await multisig.getProposalHash(account2.address, proposalSignature, false);

      const signatures = [
        await owner.signMessage(ethers.utils.arrayify(hashOwner)),
        await account1.signMessage(ethers.utils.arrayify(hashAcc1)),
        await account2.signMessage(ethers.utils.arrayify(hashAcc2))
      ];

      const execute = multisig.connect(owner).execute(
        proposalSignature,
        signatures,
        [
          owner.address,
          account1.address,
          account2.address
        ]
      );

      const ABI_ERROR = ["error IndexedError(string contractName, bytes1 errorNumber)"];
      const errorInterface = new ethers.utils.Interface(ABI_ERROR);
      const errorContract = new ethers.Contract("Errors", errorInterface, ethers.provider);

      expect(execute).to.revertedWithCustomError(
        errorContract,
        "IndexedError"
      );
    });

    it("Should be able to execute 66%", async () => {
      const { universalProfile, multisig, owner, account1, account2, account3, proposalSignature } = await loadFixture(deployContractsAndProposeExecution);

      const hashOwner = await multisig.getProposalHash(owner.address, proposalSignature, true);
      const hashAcc1  = await multisig.getProposalHash(account1.address, proposalSignature, true);
      const hashAcc2  = await multisig.getProposalHash(account2.address, proposalSignature, false);

      const signatures = [
        await owner.signMessage(ethers.utils.arrayify(hashOwner)),
        await account1.signMessage(ethers.utils.arrayify(hashAcc1)),
        await account2.signMessage(ethers.utils.arrayify(hashAcc2))
      ];

      const execute = await multisig.connect(owner).execute(
        proposalSignature,
        signatures,
        [
          owner.address,
          account1.address,
          account2.address
        ]
      );

      const key = "0x4164647265734d756c740000" + account3.address.substring(2);
      const value = "0x0000000000000000000000000000000000000000000000000000000000000fff"

      expect(await universalProfile["getData(bytes32)"](key)).to.equal(value);
    });

    it("Should be able to execute 100%", async () => {
      const { universalProfile, multisig, owner, account1, account2, account3, proposalSignature } = await loadFixture(deployContractsAndProposeExecution);

      const hashOwner = await multisig.getProposalHash(owner.address, proposalSignature, true);
      const hashAcc1  = await multisig.getProposalHash(account1.address, proposalSignature, true);
      const hashAcc2  = await multisig.getProposalHash(account2.address, proposalSignature, true);

      const signatures = [
        await owner.signMessage(ethers.utils.arrayify(hashOwner)),
        await account1.signMessage(ethers.utils.arrayify(hashAcc1)),
        await account2.signMessage(ethers.utils.arrayify(hashAcc2))
      ];

      const execute = await multisig.connect(owner).execute(
        proposalSignature,
        signatures,
        [
          owner.address,
          account1.address,
          account2.address
        ]
      );

      const key = "0x4164647265734d756c740000" + account3.address.substring(2);
      const value = "0x0000000000000000000000000000000000000000000000000000000000000fff"

      expect(await universalProfile["getData(bytes32)"](key)).to.equal(value);
    });

    it("Should not be able to execute twice", async () => {
    const { multisig, owner, account1, account2, proposalSignature } = await loadFixture(deployContractsAndProposeExecution);

      const hashOwner = await multisig.getProposalHash(owner.address, proposalSignature, true);
      const hashAcc1  = await multisig.getProposalHash(account1.address, proposalSignature, true);
      const hashAcc2  = await multisig.getProposalHash(account2.address, proposalSignature, true);

      const signatures = [
        await owner.signMessage(ethers.utils.arrayify(hashOwner)),
        await account1.signMessage(ethers.utils.arrayify(hashAcc1)),
        await account2.signMessage(ethers.utils.arrayify(hashAcc2))
      ];

      await multisig.connect(owner).execute(
        proposalSignature,
        signatures,
        [
          owner.address,
          account1.address,
          account2.address
        ]
      );

      const executeSecondTime = multisig.connect(owner).execute(
        proposalSignature,
        signatures,
        [
          owner.address,
          account1.address,
          account2.address
        ]
      );

      const ABI_ERROR = ["error IndexedError(string contractName, bytes1 errorNumber)"];
      const errorInterface = new ethers.utils.Interface(ABI_ERROR);
      const errorContract = new ethers.Contract("Errors", errorInterface, ethers.provider);

      expect(executeSecondTime).to.revertedWithCustomError(
        errorContract,
        "IndexedError"
      );
    });

    it("Should not be able to execute", async () => {
      const { multisig, account3, proposalSignature } = await loadFixture(deployContractsAndProposeExecution);

      const execute = multisig.connect(account3).execute(proposalSignature, [], []);

      const ABI_ERROR = ["error IndexedError(string contractName, bytes1 errorNumber)"];
      const errorInterface = new ethers.utils.Interface(ABI_ERROR);
      const errorContract = new ethers.Contract("Errors", errorInterface, ethers.provider);
      
      expect(execute).to.revertedWithCustomError(
        errorContract,
        "IndexedError"
      );
    });
    
  });
})