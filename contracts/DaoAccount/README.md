## Methods

### ``` function togglePermissions(address _to, bytes32[] memory _permissions) ```
|   Method properties  |                            Explanation                            |
|        :---:         |                               :---:                               |
| Method description   | Toggle permissions of an address.                                 |
| Param: `_to`         | The Universal's Profile address whose permission will be toggled. |
| Param: `_permission` | The permission that will be toggled.                              |

#### Possible permissions

| Permission name             | Permission represented in `bytes32` variable                       | BitArray of a permission |
| --------------------------- | ------------------------------------------------------------------ | ------------------------ |
| _PERMISSION_VOTE            | 0x0000000000000000000000000000000000000000000000000000000000000001 | `0000 0001 `             |
| _PERMISSION_PROPOSE         | 0x0000000000000000000000000000000000000000000000000000000000000002 | `0000 0010 `             |
| _PERMISSION_EXECUTE         | 0x0000000000000000000000000000000000000000000000000000000000000004 | `0000 0100 `             |
| _PERMISSION_SENDDELEGATE    | 0x0000000000000000000000000000000000000000000000000000000000000008 | `0000 1000 `             |
| _PERMISSION_RECIEVEDELEGATE | 0x0000000000000000000000000000000000000000000000000000000000000010 | `0001 0000 `             |
| _PERMISSION_SUPERVOTE       | 0x0000000000000000000000000000000000000000000000000000000000000020 | `0010 0000 `             |
| _PERMISSION_SUPERPROPOSE    | 0x0000000000000000000000000000000000000000000000000000000000000040 | `0100 0000 `             |
| _PERMISSION_MASTER          | 0x0000000000000000000000000000000000000000000000000000000000000080 | `1000 0000 `             |

#### Modified keys.(JSON Schemas)

The `AddressPermissions[]` key will return a `bytes16` variable which should e further transformed into a `uint128` variable which represents the length of the `AddressPermissions[]` array. To further access each element of this one needs to split the `key` into two halfs and concatenate the first half of the `key` (which would result in a `bytes16` variable), with `bytes16` variable representing a number `i`, `0 <= i < arrayLength`.
```
{
  "name": "AddressPermissions[]",
  "key": "0xdf30dba06db6a30e65354d9a64c609861f089545ca58c6b4dbe31a5f338cb0e3",
  "keyType": "Array",
  "valueType": "address",
  "valueContent": "Address"
}
```

The `AddressPermissions:DaoPermissions:<address>` key will return a BitArray which would represent the DAO permissions of a specific address. E.g. (`0000 0011` = `0x0000000000000000000000000000000000000000000000000000000000000001` + `0x0000000000000000000000000000000000000000000000000000000000000002`), this BitArray would tell us that the specific address has _PERMISSION_VOTE & _PERMISSION_PROPOSE.
```
{
  "name": "AddressPermissions:DaoPermissions:<address>",
  "key": "0x4b80742de2bfb3cc0e490000<address>",
  "keyType": "MappingWithGrouping",
  "valueType": "bytes32",
  "valueContent": "BitArray"
}
```

### ``` function delegate(address delegatee) ```

|  Method properties |                        Explanation                          |
|       :---:        |                           :---:                             |
| Method description | Delegate your vote.                                         |
| Param: `delegatee` | The address that will recieve the delate from `msg.sender`. |

#### Modified keys.(JSON Schema)

```
{
  "name": "DelegateTo:<address>",
  "key": "0x0a30e74a6c7868e400140000<address>",
  "keyType": "Mapping",
  "valueType": "address",
  "valueContent": "Address"
}
```

```
{
  "name": "AddressDelegates[]:<address>",
  "key": "0xc3f797d5c8ae536b82a60000<address>",
  "keyType": "Array[]",
  "valueType": "address[]",
  "valueContent": "Address"
}
```

### ``` function createProposal(bytes32 title, string memory description, address[] memory targets, bytes[] memory datas, uint8 choices, uint8 choicesPerVote) ```

|     Method properties   |                                   Explanation                                   |
|          :---:          |                                      :---:                                      |
| Method description      | Create a Proposal.                                                              |
| Param: `title`          | The title of the proposal. (32 characters max.)                                 |
| Param: `description`    | The description of the proposal.                                                |
| Param: `targets`        | An array of address where the calldata will be executed if the proposal passes. |
| Param: `datas`          | The calldata that will be executed if the proposal passses.                     |
| Param: `choices`        | The number of possible choices of the vote.                                     |
| Param: `choicesPerVote` | The number of choices allowed to be chosen on vote.                             |

#### Modified keys.(JSON Schema)

```
{
  "name": "<creationTimestamp>:<title>:Title",
  "key": "<creationTimestamp><title>0x00003f82a2b5852cbedcda3d9062384397479ac9a00d",
  "keyType": "Singleton",
  "valueType": "bytes32",
  "valueContent": "Bytes32"
}
```

```
{
  "name": "<creationTimestamp>:<title>:Description",
  "key": "<creationTimestamp><title>0x000095e794640ff3efd16bfe738f1a9bf2886d166af5",
  "keyType": "Singleton",
  "valueType": "string",
  "valueContent": "String"
}
```

```
{
  "name": "<creationTimestamp>:<title>:CreationTimestamp",
  "key": "<creationTimestamp><title>0x0000bd3132afbfa232f7d171a873f7e52e32c666b06d",
  "keyType": "Singleton",
  "valueType": "uint256",
  "valueContent": "Uint256"
}
```

```
{
  "name": "<creationTimestamp>:<title>:Targets[]",
  "key": "<creationTimestamp><title>0x0000ba6d4933d1a0fbfd29728a3ed8d0a7aca50635b5",
  "keyType": "Array[]",
  "valueType": "address[]",
  "valueContent": "Address"
}
```

```
{
  "name": "<creationTimestamp>:<title>:Datas[]",
  "key": "<creationTimestamp><title>0x0000478499bb6846f8a28632137c772be842c41b3105",
  "keyType": "Array[]",
  "valueType": "bytes[]",
  "valueContent": "Bytes"
}
```

```
{
  "name": "<creationTimestamp>:<title>:ProposalChoices",
  "key": "<creationTimestamp><title>0x0000e5dd8acc7154a678a0a3fa3fe2d65b8700bf702c",
  "keyType": "Singleton",
  "valueType": "uint8",
  "valueContent": "Uint8"
}
```

```
{
  "name": "<creationTimestamp>:<title>:MaximumChoicesPerVote",
  "key": "<creationTimestamp><title>0x0000ed458cca63dcf8476211a40ad15420dcabc377f0",
  "keyType": "Singleton",
  "valueType": "uint8",
  "valueContent": "Uint8"
}
```

### ``` function executeProposal(bytes10 proposalSignature) ```

| Method description | Execute the calldata of the Proposal if there is one. |
| Param: `proposalSignature` | The uniquie signature of each proposal. |
| Returns: `success` | A `boolean` variable that describes the status of the execution. |
| Returns: `res` | A `bytes memory` variable that holds any response from the execution of the calldata. |

### ``` function vote(bytes10 proposalSignature, bytes30 voteDescription, uint8[] memory choicesArray) ```

|      Method properties     |                    Explanation                      |
|            :---:           |                       :---:                         |
| Method description         | Vote on a proposal.                                 |
| Param: `proposalSignature` | The uniquie signature of each proposal.             |
| Param: `voteDescription`   | Brief description of the vote. (30 characters max). |
| Param: `choicesArray`      | A BitArray `bytes2` variable ( e.g. BitArray(`0101 0011 0010 0111`) = bytes2(`0x5327`)), there are 16 different choices and !16 different possibilities. |

#### Modified keys.(JSON Schema)

```
{
  "name": "<creationTimestamp>:<title>:<address>",
  "key": "<creationTimestamp><title><address>",
  "keyType": "Singleton",
  "valueType": "bytes32",
  "valueContent": "bytes30(VoteDescription) + bytes2(ChoicesBitArray)"
}
```
