import { ethers } from "ethers";
import UniversalProfileJSON from "../artifacts/contracts/deps/UniversalProfile.sol/UniversalProfile.json";

const deployUniversalProfile = async (
  from: string,
  newOwner: string,
  universalReceiverDelegateUP: string
) => {

  const UniversalProfile = new ethers.ContractFactory(UniversalProfileJSON.abi, UniversalProfileJSON.bytecode);
  const universalProfile = await UniversalProfile.deploy(
    newOwner,
    universalReceiverDelegateUP,
    {
      from
    }
  );

  return universalProfile;
};

export default deployUniversalProfile;