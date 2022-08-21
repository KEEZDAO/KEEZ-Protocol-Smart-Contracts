import { ethers } from "ethers";
import UniversalProfileJSON from "../artifacts/contracts/deps/UniversalProfile.sol/UniversalProfile.json" assert {type: 'json'};

const RPC_ENDPOINT = "https://rpc.l16.lukso.network";
const provider = new ethers.providers.JsonRpcProvider(RPC_ENDPOINT);

const PRIVATE_KEY = '0x0e9845dd4781fd697320f65a8dfc071424893b23786420576a6360463a69e436'; // add the private key of your EOA here (created in Step 1)
const myEOA = new ethers.Wallet(PRIVATE_KEY, provider);

const deployUniversalProfile = async () => {

  const UniversalProfile = new ethers.ContractFactory(
    UniversalProfileJSON.abi,
    UniversalProfileJSON.bytecode,
    myEOA
  );
  const universalProfile = await UniversalProfile.deploy(
    myEOA.address,
    myEOA.address
  );

  console.log(universalProfile);

}

deployUniversalProfile();