var DaoAccount = artifacts.require("DaoAccount");
var DaoAccountMetadata = artifacts.require("DaoAccountMetadata");
var DaoDelegates = artifacts.require("DaoDelegates");
var DaoPermissions = artifacts.require("DaoPermissions");
var DaoProposals = artifacts.require("DaoProposals");
var DaoParticipation = artifacts.require("DaoParticipation");
var DaoVotingStrategies = artifacts.require("DaoVotingStrategies");

module.exports = async function(deployer) {

  await deployer.deploy(DaoAccountMetadata);
  const daoAccountMetadata = await DaoAccountMetadata.deployed();

  await deployer.deploy(DaoDelegates);
  const daoDelegates = await DaoDelegates.deployed();

  await deployer.deploy(DaoPermissions);
  const daoPermissions = await DaoPermissions.deployed();

  await deployer.deploy(DaoProposals);
  const daoProposals = await DaoProposals.deployed();

  await deployer.deploy(DaoParticipation);
  const daoParticipation = await DaoParticipation.deployed();

  await deployer.deploy(DaoVotingStrategies);
  const daoVotingStrategies = await DaoVotingStrategies.deployed();

  await deployer.deploy(
    DaoAccount,
    "DaoName",
    "DaoDescription",
    10,
    10,
    60,
    60,
    daoAccountMetadata,
    daoDelegates,
    daoPermissions,
    daoProposals,
    daoParticipation,
    daoVotingStrategies
  );
  const daoAccount = await DaoAccount.deployed();

};