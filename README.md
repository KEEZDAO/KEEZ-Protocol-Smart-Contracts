# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
GAS_REPORT=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```

## Errors

### This are the errors that you can get while using `DaoPermissions.sol`

| Error number |                               Error explanation                                     |
|     :---:    |                                     :---:                                           |
|    `0x01`    | Method caller is wrong or the signature is invalid.                                 |

### This are the errors that you can get while using `DaoDelegates.sol`

| Error number |                               Error explanation                                     |
|     :---:    |                                     :---:                                           |
|    `0x01`    | User already delegated the vote.                                                    |
|    `0x02`    | Current delegatee is the same as the new delegatee.                                 |
|    `0x03`    | There is no delegatee to be removed.                                                |

### This are the errors that you can get while using `DaoProposals.sol`

| Error number |                               Error explanation                                     |
|     :---:    |                                     :---:                                           |
|    `0x01`    | The number of choices per vote must be smaller than the number of total choices.    |
|    `0x02`    | The voting delay is smaller than the minimum value allowed.                         |
|    `0x03`    | The voting period is smaller than the minimum value allowed.                        |
|    `0x04`    | The execution delay is smaller than the minimum value allowed.                      |
|    `0x05`    | The proposal's cumulative time did not expire.                                      |
|    `0x06`    | The number of signatures, the number of signers and the number of choises bit arrays are not equal. |

### This are the errors that you can get while using `MultisigKeyManager.sol`

| Error number |                               Error explanation                                     |
|     :---:    |                                     :---:                                           |
|    `0x01`    | The recovered address is not the same as the one that allowed claiming permissions. |
|    `0x02`    | `_targets.length` must be equal to `_datas.length`.                                 |
|    `0x03`    | `_signatures.length` must be equal to `_signers.length`.                            |
|    `0x04`    | Not enough signatures for a successful proposal.                                    |
|    `0x05`    | Not enough positive votes for a successful proposal.                                |