import { ethers } from "ethers";
import UniversalReceiverDelegateUPJSON from "../artifacts/contracts/deps/UniversalReceiverDelegateUP.sol/UniversalReceiverDelegateUP.json" assert {type: 'json'};

import DaoPermissionsDeployerJSON from "../artifacts/contracts/Deployer/DaoDeployer/DaoPermissions/DaoPermissionsDeployer.sol/DaoPermissionsDeployer.json" assert {type: 'json'};
import DaoDelegatesDeployerJSON from "../artifacts/contracts/Deployer/DaoDeployer/DaoDelegates/DaoDelegatesDeployer.sol/DaoDelegatesDeployer.json" assert {type: 'json'};
import DaoProposalsDeployerJSON from "../artifacts/contracts/Deployer/DaoDeployer/DaoProposals/DaoProposalsDeployer.sol/DaoProposalsDeployer.json" assert {type: 'json'};

import UniversalProfileDeployerJSON from "../artifacts/contracts/Deployer/UniversalProfileDeployer.sol/UniversalProfileDeployer.json" assert {type: 'json'};

import DaoDeployerJSON from "../artifacts/contracts/Deployer/DaoDeployer/DaoDeployer.sol/DaoDeployer.json" assert {type: 'json'};

import MultisigDeployerJSON from "../artifacts/contracts/Deployer/MultisigDeployer.sol/MultisigDeployer.json" assert {type: 'json'};

import DeployerJSON from "../artifacts/contracts/Deployer/Deployer.sol/Deployer.json" assert {type: 'json'};

const RPC_ENDPOINT = "https://rpc.l16.lukso.network";
const provider = new ethers.providers.JsonRpcProvider(RPC_ENDPOINT);

const PRIVATE_KEY = '0x0e9845dd4781fd697320f65a8dfc071424893b23786420576a6360463a69e436'; // add the private key of your EOA here (created in Step 1)
const myEOA = new ethers.Wallet(PRIVATE_KEY, provider);

const createDeployer = async () => {

  const UniversalReceiverDelegateUP = new ethers.ContractFactory(
    UniversalReceiverDelegateUPJSON.abi,
    UniversalReceiverDelegateUPJSON.bytecode,
    myEOA
  );
  const universalReceiverDelegateUP = await UniversalReceiverDelegateUP.deploy();

  const DaoPermissionsDeployer = new ethers.ContractFactory(
    DaoPermissionsDeployerJSON.abi,
    DaoPermissionsDeployerJSON.bytecode,
    myEOA
  );
  const daoPermissionsDeployer = await DaoPermissionsDeployer.deploy();

  const DaoDelegatesDeployer = new ethers.ContractFactory(
    DaoDelegatesDeployerJSON.abi,
    DaoDelegatesDeployerJSON.bytecode,
    myEOA
  );
  const daoDelegatesDeployer = await DaoDelegatesDeployer.deploy();

  const DaoProposalsDeployer = new ethers.ContractFactory(
    DaoProposalsDeployerJSON.abi,
    DaoProposalsDeployerJSON.bytecode,
    myEOA
  );
  const daoProposalsDeployer = await DaoProposalsDeployer.deploy();

  const UniversalProfileDeployer = new ethers.ContractFactory(
    UniversalProfileDeployerJSON.abi,
    UniversalProfileDeployerJSON.bytecode,
    myEOA
  );
  const universalProfileDeployer = await UniversalProfileDeployer.deploy();

  const DaoDeployer = new ethers.ContractFactory(
    DaoDeployerJSON.abi,
    DaoDeployerJSON.bytecode,
    myEOA
  );
  const daoDeployer = await DaoDeployer.deploy(
    daoPermissionsDeployer.address,
    daoDelegatesDeployer.address,
    daoProposalsDeployer.address
  );

  const MultisigDeployer = new ethers.ContractFactory(
    MultisigDeployerJSON.abi,
    MultisigDeployerJSON.bytecode,
    myEOA
  );
  const multisigDeployer = await MultisigDeployer.deploy();

  const Deployer = new ethers.ContractFactory(
    DeployerJSON.abi,
    DeployerJSON.bytecode,
    myEOA
  );
  const deployer = await Deployer.deploy(
    universalProfileDeployer.address,
    daoDeployer.address,
    multisigDeployer.address
  );

  return {
    universalReceiverDelegateUPAddress: universalReceiverDelegateUP.address,
    daoPermissionsDeployerAddress: daoPermissionsDeployer.address,
    daoDelegatesDeployerAddress: daoDelegatesDeployer.address,
    daoProposalsDeployerAddress: daoProposalsDeployer.address,
    universalProfileDeployerAddress: universalProfileDeployer.address,
    daoDeployerAddress: daoDeployer.address,
    multisigDeployerAddress: multisigDeployer.address,
    deployerAddress: deployer.address
  };

}

const deployer = await createDeployer();
console.log(deployer);