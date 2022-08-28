import { ethers } from "hardhat";
import { expect } from "chai";
import { DaoDeployer, Deployer, MultisigDeployer, UniversalReceiverDelegateUP } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export type DeployerContext = {
  accounts: SignerWithAddress[];
  deployer: Deployer;
  daoDeployer: DaoDeployer;
  multisigDeployer: MultisigDeployer;
  universalReceiverDelegateUP: UniversalReceiverDelegateUP;
};

describe("Deployment of the universal deployer", async () => {
  let context: DeployerContext;

  before(async () => {
    const accounts = await ethers.getSigners();

    const UniversalReceiverDelegateUP = await ethers.getContractFactory("UniversalReceiverDelegateUP");
    const universalReceiverDelegateUP = await UniversalReceiverDelegateUP.deploy();

    const DaoPermissionsDeployer = await ethers.getContractFactory("DaoPermissionsDeployer");
    const daoPermissionsDeployer = await DaoPermissionsDeployer.deploy();
    const DaoDelegatesDeployer = await ethers.getContractFactory("DaoDelegatesDeployer");
    const daoDelegatesDeployer = await DaoDelegatesDeployer.deploy();
    const DaoProposalsDeployer = await ethers.getContractFactory("DaoProposalsDeployer");
    const daoProposalsDeployer = await DaoProposalsDeployer.deploy();

    const UniversalProfileDeployer = await ethers.getContractFactory("UniversalProfileDeployer");
    const universalProfileDeployer = await UniversalProfileDeployer.deploy();
    const DaoDeployer = await ethers.getContractFactory("DaoDeployer");
    const daoDeployer = await DaoDeployer.deploy(
      daoPermissionsDeployer.address,
      daoDelegatesDeployer.address,
      daoProposalsDeployer.address
    );
    const MultisigDeployer = await ethers.getContractFactory("MultisigDeployer");
    const multisigDeployer = await MultisigDeployer.deploy();

    const Deployer = await ethers.getContractFactory("Deployer");
    const deployer = await Deployer.deploy(
      universalProfileDeployer.address,
      daoDeployer.address,
      multisigDeployer.address
    );
    context = {
      accounts,
      daoDeployer,
      multisigDeployer,
      deployer,
      universalReceiverDelegateUP
    };
  });

  it("Should deploy a new Universal Profile, DAO and Multisig", async () => {
    const deployment = await context.deployer
      .connect(context.accounts[0])
      ["deploy(address,bytes,bytes32[],address[],bytes32[],bytes32,address[],bytes32[])"](
        context.universalReceiverDelegateUP.address,
        ethers.utils.hexlify(ethers.utils.toUtf8Bytes("https://somelink.com/universal-profile-metadata")),
        [
          ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
          ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
          ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
          ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
          ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32)
        ],
        [
          context.accounts[0].address,
          context.accounts[1].address,
          context.accounts[2].address
        ],
        [
          "0x00000000000000000000000000000000000000000000000000000000000000ff",
          "0x00000000000000000000000000000000000000000000000000000000000000ff",
          "0x00000000000000000000000000000000000000000000000000000000000000ff"
        ],
        ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
        [
          context.accounts[0].address,
          context.accounts[1].address,
          context.accounts[2].address
        ],
        [
          "0x000000000000000000000000000000000000000000000000000000000000001f",
          "0x000000000000000000000000000000000000000000000000000000000000001f",
          "0x000000000000000000000000000000000000000000000000000000000000000f"
        ]
      );
      
    const userAddresses = await context.deployer
      .connect(context.accounts[0])
      .getAddresses();

    await expect(deployment)
      .to.emit(context.daoDeployer, "DaoDeployed")
      .withArgs(userAddresses[2], userAddresses[3], userAddresses[4]);
  
    await expect(deployment)
      .to.emit(context.multisigDeployer, "MultisigDeployed")
      .withArgs(userAddresses[5]);
      
    const UniversalProfile = await ethers.getContractFactory("LSP0ERC725Account");
    const universalProfile = UniversalProfile.attach(userAddresses[0]);

    console.log(await universalProfile.owner());
    console.log(userAddresses[1]);

    const keys = [
      "0x0cfc51aec37c55a4d0b1a65c6255c4bf2fbdf6277f3cc0730c45b828b6db8b47",
      "0xeafec4d89fa9619884b60000abe425d64acd861a49b8ddf5c0b6962110481f38",
      "0x5ef83ad9559033e6e941db7d7c495acdce616347d28e90c7ce47cbfcfcad3bc5",
      // DAO Settings
      "0xbc776f168e7b9c60bb2a7180950facd372cd90c841732d963c31a93ff9f8c127",
      "0xf89f507ecd9cb7646ce1514ec6ab90d695dac9314c3771f451fd90148a3335a9",
      "0x799787138cc40d7a47af8e69bdea98db14e1ead8227cef96814fa51751e25c76",
      "0xd3cf4cd71858ea36c3f5ce43955db04cbe9e1f42a2c7795c25c1d430c9bb280a",
      "0xb207580c05383177027a90d6c298046d3d60dfa05a32b0bb48ea9015e11a3424",
      // DAO Participants
      "0xf7f9c7410dd493d79ebdaee15bbc77fd163bd488f54107d1be6ed34b1e099004",
      "0xf7f9c7410dd493d79ebdaee15bbc77fd" + ethers.utils.hexZeroPad(ethers.utils.hexValue(0), 16).substring(2),
      "0xf7f9c7410dd493d79ebdaee15bbc77fd" + ethers.utils.hexZeroPad(ethers.utils.hexValue(1), 16).substring(2),
      "0xf7f9c7410dd493d79ebdaee15bbc77fd" + ethers.utils.hexZeroPad(ethers.utils.hexValue(2), 16).substring(2),
      "0xf7f9c7410dd493d79ebd0000" + context.accounts[0].address.substring(2),
      "0xf7f9c7410dd493d79ebd0000" + context.accounts[1].address.substring(2),
      "0xf7f9c7410dd493d79ebd0000" + context.accounts[2].address.substring(2),
      // DAO Partcipants permissions
      "0x4b80742de2bfb3cc0e490000" + context.accounts[0].address.substring(2),
      "0x4b80742de2bfb3cc0e490000" + context.accounts[1].address.substring(2),
      "0x4b80742de2bfb3cc0e490000" + context.accounts[2].address.substring(2),
      // Multisig Settings
      "0x47499aa724781173ffff2a8a82c6223b88e1a838d32bb91a9ff9c9c0b8c8759b",
      // Multisig Participants
      "0x54aef89da199194b126d28036f71291726191dbff7160f9d0986952b17eaedb4",
      "0x54aef89da199194b126d28036f712917" + ethers.utils.hexZeroPad(ethers.utils.hexValue(0), 16).substring(2),
      "0x54aef89da199194b126d28036f712917" + ethers.utils.hexZeroPad(ethers.utils.hexValue(1), 16).substring(2),
      "0x54aef89da199194b126d28036f712917" + ethers.utils.hexZeroPad(ethers.utils.hexValue(2), 16).substring(2),
      "0x54aef89da199194b126d0000" + context.accounts[0].address.substring(2),
      "0x54aef89da199194b126d0000" + context.accounts[1].address.substring(2),
      "0x54aef89da199194b126d0000" + context.accounts[2].address.substring(2),
      // Multisig Participants Permissions
      "0x4164647265734d756c740000" + context.accounts[0].address.substring(2),
      "0x4164647265734d756c740000" + context.accounts[1].address.substring(2),
      "0x4164647265734d756c740000" + context.accounts[2].address.substring(2),
    ];
    const values = [
      context.universalReceiverDelegateUP.address,
      "0xabe425d6",
      ethers.utils.hexlify(ethers.utils.toUtf8Bytes("https://somelink.com/universal-profile-metadata")),
      // DAO Settings
      ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
      // DAO Participants
      ethers.utils.hexZeroPad(ethers.utils.hexValue(3), 32),
      context.accounts[0].address,
      context.accounts[1].address,
      context.accounts[2].address,
      ethers.utils.hexZeroPad(ethers.utils.hexValue(0), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(1), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(2), 32),
      // DAO Participants permissions
      ethers.utils.hexZeroPad(ethers.utils.hexValue(255), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(255), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(255), 32),
      // Multisig Settings
      ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
      // Multisig Participants
      ethers.utils.hexZeroPad(ethers.utils.hexValue(3), 32),
      context.accounts[0].address,
      context.accounts[1].address,
      context.accounts[2].address,
      ethers.utils.hexZeroPad(ethers.utils.hexValue(0), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(1), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(2), 32),
      // Multisig Participants Permissions
      ethers.utils.hexZeroPad(ethers.utils.hexValue(31), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(31), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(15), 32),
    ];

    expect(await universalProfile["getData(bytes32[])"](keys)).to.deep.equal(values);
  });

  it("Should deploy a new Universal Profile and DAO", async () => {
    const deployment = await context.deployer
      .connect(context.accounts[0])
      ["deploy(address,bytes,bytes32,bytes32,bytes32,bytes32,bytes32,address[],bytes32[])"](
        context.universalReceiverDelegateUP.address,
        ethers.utils.hexlify(ethers.utils.toUtf8Bytes("https://somelink.com/universal-profile-metadata")),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
        [
          context.accounts[0].address,
          context.accounts[1].address,
          context.accounts[2].address
        ],
        [
          "0x00000000000000000000000000000000000000000000000000000000000000ff",
          "0x00000000000000000000000000000000000000000000000000000000000000ff",
          "0x00000000000000000000000000000000000000000000000000000000000000ff"
        ]
      );
      
    const userAddresses = await context.deployer
      .connect(context.accounts[0])
      .getAddresses();
  
    await expect(deployment)
      .to.emit(context.daoDeployer, "DaoDeployed")
      .withArgs(userAddresses[2], userAddresses[3], userAddresses[4]);

    const UniversalProfile = await ethers.getContractFactory("LSP0ERC725Account");
    const universalProfile = UniversalProfile.attach(userAddresses[0]);

    const keys = [
      "0x0cfc51aec37c55a4d0b1a65c6255c4bf2fbdf6277f3cc0730c45b828b6db8b47",
      "0xeafec4d89fa9619884b60000abe425d64acd861a49b8ddf5c0b6962110481f38",
      "0x5ef83ad9559033e6e941db7d7c495acdce616347d28e90c7ce47cbfcfcad3bc5",
      // DAO Settings
      "0xbc776f168e7b9c60bb2a7180950facd372cd90c841732d963c31a93ff9f8c127",
      "0xf89f507ecd9cb7646ce1514ec6ab90d695dac9314c3771f451fd90148a3335a9",
      "0x799787138cc40d7a47af8e69bdea98db14e1ead8227cef96814fa51751e25c76",
      "0xd3cf4cd71858ea36c3f5ce43955db04cbe9e1f42a2c7795c25c1d430c9bb280a",
      "0xb207580c05383177027a90d6c298046d3d60dfa05a32b0bb48ea9015e11a3424",
      // DAO Participants
      "0xf7f9c7410dd493d79ebdaee15bbc77fd163bd488f54107d1be6ed34b1e099004",
      "0xf7f9c7410dd493d79ebdaee15bbc77fd" + ethers.utils.hexZeroPad(ethers.utils.hexValue(0), 16).substring(2),
      "0xf7f9c7410dd493d79ebdaee15bbc77fd" + ethers.utils.hexZeroPad(ethers.utils.hexValue(1), 16).substring(2),
      "0xf7f9c7410dd493d79ebdaee15bbc77fd" + ethers.utils.hexZeroPad(ethers.utils.hexValue(2), 16).substring(2),
      "0xf7f9c7410dd493d79ebd0000" + context.accounts[0].address.substring(2),
      "0xf7f9c7410dd493d79ebd0000" + context.accounts[1].address.substring(2),
      "0xf7f9c7410dd493d79ebd0000" + context.accounts[2].address.substring(2),
      // DAO Partcipants permissions
      "0x4b80742de2bfb3cc0e490000" + context.accounts[0].address.substring(2),
      "0x4b80742de2bfb3cc0e490000" + context.accounts[1].address.substring(2),
      "0x4b80742de2bfb3cc0e490000" + context.accounts[2].address.substring(2),
    ];
    const values = [
      context.universalReceiverDelegateUP.address,
      "0xabe425d6",
      ethers.utils.hexlify(ethers.utils.toUtf8Bytes("https://somelink.com/universal-profile-metadata")),
      // DAO Settings
      ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
      // DAO Participants
      ethers.utils.hexZeroPad(ethers.utils.hexValue(3), 32),
      context.accounts[0].address,
      context.accounts[1].address,
      context.accounts[2].address,
      ethers.utils.hexZeroPad(ethers.utils.hexValue(0), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(1), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(2), 32),
      // DAO Partcipants permissions
      ethers.utils.hexZeroPad(ethers.utils.hexValue(255), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(255), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(255), 32),
    ];

    expect(await universalProfile["getData(bytes32[])"](keys)).to.deep.equal(values);
  });

  it("Should deploy a new Universal Profile and Multisig", async () => {
    const deployment = await context.deployer
      .connect(context.accounts[0])
        ["deploy(address,bytes,bytes32,address[],bytes32[])"](
        context.universalReceiverDelegateUP.address,
        ethers.utils.hexlify(ethers.utils.toUtf8Bytes("https://somelink.com/universal-profile-metadata")),
        ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
        [
          context.accounts[0].address,
          context.accounts[1].address,
          context.accounts[2].address
        ],
        [
          "0x000000000000000000000000000000000000000000000000000000000000001f",
          "0x000000000000000000000000000000000000000000000000000000000000001f",
          "0x000000000000000000000000000000000000000000000000000000000000000f"
        ]
      );
      
    const userAddresses = await context.deployer
      .connect(context.accounts[0])
      .getAddresses();

    await expect(deployment)
      .to.emit(context.multisigDeployer, "MultisigDeployed")
      .withArgs(userAddresses[5]);
      
    const UniversalProfile = await ethers.getContractFactory("LSP0ERC725Account");
    const universalProfile = UniversalProfile.attach(userAddresses[0]);

    const keys = [
      "0x0cfc51aec37c55a4d0b1a65c6255c4bf2fbdf6277f3cc0730c45b828b6db8b47",
      "0xeafec4d89fa9619884b60000abe425d64acd861a49b8ddf5c0b6962110481f38",
      "0x5ef83ad9559033e6e941db7d7c495acdce616347d28e90c7ce47cbfcfcad3bc5",
      // Multisig Settings
      "0x47499aa724781173ffff2a8a82c6223b88e1a838d32bb91a9ff9c9c0b8c8759b",
      // Multisig Participants
      "0x54aef89da199194b126d28036f71291726191dbff7160f9d0986952b17eaedb4",
      "0x54aef89da199194b126d28036f712917" + ethers.utils.hexZeroPad(ethers.utils.hexValue(0), 16).substring(2),
      "0x54aef89da199194b126d28036f712917" + ethers.utils.hexZeroPad(ethers.utils.hexValue(1), 16).substring(2),
      "0x54aef89da199194b126d28036f712917" + ethers.utils.hexZeroPad(ethers.utils.hexValue(2), 16).substring(2),
      "0x54aef89da199194b126d0000" + context.accounts[0].address.substring(2),
      "0x54aef89da199194b126d0000" + context.accounts[1].address.substring(2),
      "0x54aef89da199194b126d0000" + context.accounts[2].address.substring(2),
      // Multisig Participants Permissions
      "0x4164647265734d756c740000" + context.accounts[0].address.substring(2),
      "0x4164647265734d756c740000" + context.accounts[1].address.substring(2),
      "0x4164647265734d756c740000" + context.accounts[2].address.substring(2),
    ];
    const values = [
      context.universalReceiverDelegateUP.address,
      "0xabe425d6",
      ethers.utils.hexlify(ethers.utils.toUtf8Bytes("https://somelink.com/universal-profile-metadata")),
      // Multisig Settings
      ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
      // Multisig Participants
      ethers.utils.hexZeroPad(ethers.utils.hexValue(3), 32),
      context.accounts[0].address,
      context.accounts[1].address,
      context.accounts[2].address,
      ethers.utils.hexZeroPad(ethers.utils.hexValue(0), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(1), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(2), 32),
      // Multisig Participants Permissions
      ethers.utils.hexZeroPad(ethers.utils.hexValue(31), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(31), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(15), 32),
    ];

    expect(await universalProfile["getData(bytes32[])"](keys)).to.deep.equal(values);
  });

  it.skip("Should encode the data correctly", async () => {
    const DeployerUtils = await ethers.getContractFactory("DeployerUtils");
    const deployerUtils = await DeployerUtils.deploy();

    const encodedData = await deployerUtils.encodeDaoData(
      ethers.utils.hexlify(ethers.utils.toUtf8Bytes("https://somelink.com/")),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(50), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
      ethers.utils.hexZeroPad(ethers.utils.hexValue(60), 32),
      [
        context.accounts[0].address,
        context.accounts[1].address,
        context.accounts[2].address
      ],
      [
        "0x00000000000000000000000000000000000000000000000000000000000000ff",
        "0x00000000000000000000000000000000000000000000000000000000000000ff",
        "0x00000000000000000000000000000000000000000000000000000000000000ff"
      ]
    );

    console.log(encodedData);
  });
});
