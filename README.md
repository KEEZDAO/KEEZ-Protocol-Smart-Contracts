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

### This are the errors that you can get while using `DaoKeyManager.js`

| Error number |                               Error explanation                                     |
|     :---:    |                                     :---:                                           |
|    `0x01`    | The recovered address is not the same as the one that allowed claiming permissions. |
|    `0x02`    | User already delegated the vote to this delegatee.                                  |
|    `0x03`    | You can have maximum 16 choices.                                                    |
|    `0x04`    | The number of choices per vote must be smaller than the number of total choices.    |
|    `0x05`    | The voting delay is smaller than the minimum value allowed.                         |
|    `0x06`    | The voting period is smaller than the minimum value allowed.                        |
|    `0x06`    | The proposal's time did not expire.                                                 |
|    `0x07`    | There are no methods to execute.                                                    |
|    `0x08`    | User has already voted.                                                             |
|    `0x09`    | User has more choices than allowed.                                                 |

### This are the errors that you can get while using `MultisigKeyManager.js`

| Error number |                               Error explanation                                     |
|     :---:    |                                     :---:                                           |
|    `0x01`    | The recovered address is not the same as the one that allowed claiming permissions. |
|    `0x02`    | `_targets.length` must be equal to `_datas.length`.                                 |
|    `0x03`    | `_signatures.length` must be equal to `_signers.length`.                            |
|    `0x04`    | Not enough signatures for a successful proposal.                                    |
|    `0x05`    | Not enough positive votes for a successful proposal.                                |