import { ethers } from "hardhat";
import { expect } from "chai";
import { Deployer, Deployer__factory, LSP0ERC725Account__factory } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { lsp0Erc725Account } from "../typechain-types/@lukso/lsp-smart-contracts/contracts";

export type DeployerContext = {
  accounts: SignerWithAddress[];
  DeployerContract: Deployer__factory;
  deployerContract: Deployer;
};

describe("Contracts deployment", async () => {
  let context: DeployerContext;

  before(async () => {
    const accounts = await ethers.getSigners();
    const DeployerContract = await ethers.getContractFactory("Deployer");
    const deployerContract = await DeployerContract.deploy();
    context = {
      accounts,
      DeployerContract,
      deployerContract,
    };
  });

  it("Should deploy a new Universal Profile", async () => {
    await context.deployerContract
      .connect(context.accounts[0])
      .initialize(
        context.accounts[0].address,
        "0x00"
      );
      
    const userAddresses = await context.deployerContract
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
