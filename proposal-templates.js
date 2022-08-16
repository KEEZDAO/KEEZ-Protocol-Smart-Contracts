import { ethers } from "hardhat";

const updateUserPermission = (address, permissions) => {
  const ABI = ["function setData(bytes32 dataKey, bytes memory dataValue)"];
  const ERC725Yinterface = new ethers.utils.Interface(ABI);
  const payloads = [
    ERC725Yinterface.encodeFunctionData(
      "setData",
      [
        "0x4b80742de2bfb3cc0e490000" + address.substring(2),
        permissions
      ]
    )
  ];
  return payloads;
}

console.log(
  updateUserPermission(
    ethers.utils.hexZeroPad(ethers.utils.hexValue(0), 20),
    ethers.utils.hexZeroPad(ethers.utils.hexValue(255), 32)
  )
);