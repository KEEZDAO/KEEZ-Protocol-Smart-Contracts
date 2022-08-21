import { ethers } from "hardhat";
import { expect } from "chai";
import { Deployer, Deployer__factory, UniversalReceiverDelegateUP } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export type DeployerContext = {
  accounts: SignerWithAddress[];
  Deployer: Deployer__factory;
  deployer: Deployer;
  universalReceiverDelegateUP: UniversalReceiverDelegateUP;
};

describe("Contracts deployment", async () => {
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
      Deployer,
      deployer,
      universalReceiverDelegateUP
    };
  });

  it("Should deploy a new Universal Profile", async () => {
    await context.deployer
      .connect(context.accounts[0])
      ["deploy(address,bytes,bytes,bytes32[],address[],bytes32[],bytes,bytes32,address[],bytes32[])"](
        context.universalReceiverDelegateUP.address,
        ethers.utils.hexlify(ethers.utils.toUtf8Bytes("https://somelink.com/")),
        ethers.utils.hexlify(ethers.utils.toUtf8Bytes("https://somelink.com/")),
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
        ethers.utils.hexlify(ethers.utils.toUtf8Bytes("https://somelink.com/")),
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

    const UniversalProfile = await ethers.getContractFactory("LSP0ERC725Account");
    const universalProfile = UniversalProfile.attach(userAddresses[0]);

    const keys = [
      "0x0cfc51aec37c55a4d0b1a65c6255c4bf2fbdf6277f3cc0730c45b828b6db8b47",
      "0xeafec4d89fa9619884b60000abe425d64acd861a49b8ddf5c0b6962110481f38",
      "0x5ef83ad9559033e6e941db7d7c495acdce616347d28e90c7ce47cbfcfcad3bc5",
    ];
    const values = [context.accounts[0].address, "0xabe425d6", "0x00"];

    expect(await universalProfile["getData(bytes32[])"](keys)).to.deep.equal(values);
  });
});
