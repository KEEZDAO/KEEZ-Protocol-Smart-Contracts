import { ethers, Signer } from "ethers";
import UniversalProfileJSON from "../artifacts/contracts/deps/UniversalProfile.sol/UniversalProfile.json";

/*
const RPC_ENDPOINT = "https://rpc.l16.lukso.network";
const provider = new ethers.providers.JsonRpcProvider(RPC_ENDPOINT);
*/

const deployUniversalProfile = async (
  signer: Signer,
  newOwner: string,
  universalReceiverDelegateUP: string
) => {

  const UniversalProfile = new ethers.ContractFactory(
    UniversalProfileJSON.abi,
    UniversalProfileJSON.bytecode,
    signer
  );
  const universalProfile = await UniversalProfile.deploy(
    newOwner,
    universalReceiverDelegateUP,
    {
      from: signer.getAddress()
    }
  );

  return universalProfile;
};

export default deployUniversalProfile;