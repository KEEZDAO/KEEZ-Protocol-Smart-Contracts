import { ethers } from "hardhat";

const updateUserPermission = (address, permissions) => {
  const setDataABI = ["function setData(bytes32 dataKey, bytes memory dataValue)"];
  const setDataInterface = new ethers.utils.Interface(setDataABI);
  const payloads = [
    setDataInterface.encodeFunctionData(
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


const _DAO_JSON_METDATA_KEY = "0x529fc5ec0943a0370fe51d4dec0787294933572592c61b103d9e170cb15e8e79";
const _DAO_MAJORITY_KEY = "0xbc776f168e7b9c60bb2a7180950facd372cd90c841732d963c31a93ff9f8c127"; // --> uint8
const _DAO_PARTICIPATION_RATE_KEY = "0xf89f507ecd9cb7646ce1514ec6ab90d695dac9314c3771f451fd90148a3335a9"; // --> uint8
const _DAO_MINIMUM_VOTING_DELAY_KEY = "0x799787138cc40d7a47af8e69bdea98db14e1ead8227cef96814fa51751e25c76"; // --> uint256
const _DAO_MINIMUM_VOTING_PERIOD_KEY = "0xd3cf4cd71858ea36c3f5ce43955db04cbe9e1f42a2c7795c25c1d430c9bb280a"; // --> uint256
const _DAO_MINIMUM_EXECUTION_DELAY_KEY = "0xb207580c05383177027a90d6c298046d3d60dfa05a32b0bb48ea9015e11a3424"; // --> uint256

const changeParameters = (datakeys, dataValues) => {
  const setDataABI = ["function setData(bytes32[] memory dataKeys, bytes[] memory dataValues)"];
  const setDataInterface = new ethers.utils.Interface(setDataABI);
  const payloads = [
    setDataInterface.encodeFunctionData(
      "setData",
      [
        datakeys,
        dataValues
      ]
    )
  ];
  return payloads;
}

changeParameters(
  [
    _DAO_JSON_METDATA_KEY,
    _DAO_MAJORITY_KEY,
    _DAO_PARTICIPATION_RATE_KEY,
    _DAO_MINIMUM_VOTING_DELAY_KEY,
    _DAO_MINIMUM_VOTING_PERIOD_KEY,
    _DAO_MINIMUM_EXECUTION_DELAY_KEY
  ],
  [
    "new metadata link",
    "new majority",
    "new participation rate",
    "new minimum voting delay",
    "new minimum voting period",
    "new minimum execution delay"
  ]
);

const transferTokens = (
  tokenAddress,
  from,
  to,
  amount,
  force,
  data
) => {
  const transferABI = ["transfer(address from, address to, uint256 amount, bool force, bytes memory data)"];
  const transferInterface = new ethers.utils.Interface(transferABI);
  const transferPayload = transferInterface.encodeFunctionData(
    "transfer",
    [
      from,
      to,
      amount,
      force,
      data
    ]
  );
  const executeABI = ["function execute(uint256 operation, address to, uint256 value, bytes calldata data"];
  const executeInterface = new ethers.utils.Interface(executeABI);
  const payloads = [
    executeInterface.encodeFunctionData(
      "execute",
      [
        0,
        tokenAddress,
        0,
        transferPayload 
      ]
    )
  ];
  return payloads;
}