var DaoCreator = artifacts.require("DaoCreator");

module.exports = async function(deployer) {

  await deployer.deploy(DaoCreator);
  const daoCreator = await DaoCreator.deployed();

  daoCreator.createUniversalProfile();
  daoCreator.createDaoKeymanager();

};