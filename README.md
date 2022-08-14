# Useful commands

## Compile normal:

```shell
npm run compile:normal
```

## Compile force:

```shell
npm run compile:force
```

## Test all contracts:

```shell
npm run test
```

## Test DAO contracts:

```shell
npm run test:dao
```

## Test Multisig Contracts:

```shell
npm run test:multisig
```

## Errors

### These are the errors that you can get while using `DaoPermissions.sol`

| Error number | Error explanation                                   |
| :----------: | :-------------------------------------------------: |
| `0x01`       | Method caller is wrong or the signature is invalid. |

### These are the errors that you can get while using `DaoDelegates.sol`

| Error number | Error explanation                                   |
| :----------: | :-------------------------------------------------: |
| `0x01`       | User already delegated the vote.                    |
| `0x02`       | There is no delegatee to be changed.                |
| `0x03`       | Current delegatee is the same as the new delegatee. |
| `0x04`       | There is no delegatee to be removed.                |

### These are the errors that you can get while using `DaoProposals.sol`

| Error number | Error explanation                                     |
| :----------: | :-------------------------------------------------------------------------------------------------: |
| `0x01`       | The number of choices per vote must be smaller than the number of total choices.                    |
| `0x02`       | The voting delay is smaller than the minimum value allowed.                                         |
| `0x03`       | The voting period is smaller than the minimum value allowed.                                        |
| `0x04`       | The execution delay is smaller than the minimum value allowed.                                      |
| `0x05`       | The number of signatures, the number of signers and the number of choises bit arrays are not equal. |
| `0x06`       | The proposal's voting delay did not expire.                                                         |
| `0x07`       | The proposal's voting period did expire.                                                            |
| `0x08`       | The proposal's voting delay, voting period and execution delay did not expire.                      |

### These are the errors that you can get while using `MultisigKeyManager.sol`

| Error number |                               Error explanation                                     |
|     :---:    |                                     :---:                                           |
|    `0x01`    | The recovered address is not the same as the one that allowed claiming permissions. |
|    `0x02`    | `_targets.length` must be equal to `_datas.length`.                                 |
|    `0x03`    | `_signatures.length` must be equal to `_signers.length`.                            |
|    `0x04`    | Not enough signatures for a successful proposal.                                    |
|    `0x05`    | Not enough positive votes for a successful proposal.                                |