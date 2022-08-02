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

| Error number |                               Error explanation                                  |
|     :---:    |                                     :---:                                        |
| `0x0001`     | `targets.length` must be equal to `datas.length`.                                |
| `0x0002`     | You can have maximum 16 choices.                                                 |
| `0x0003`     | The number of choices per vote must be smaller than the number of total choices. |
| `0x0004`     | The voting delay is smaller than the minimum value allowed.                      |
| `0x0005`     | The voting period is smaller than the minimum value allowed.                     |
| `0x0006`     | The proposal's time did not expire.                                              |
| `0x0007`     | There are no methods to execute.                                                 |
| `0x0008`     | User has already voted.                                                          |
| `0x0009`     | User has more choices than allowed.                                              |
| `0x0010`     | `_to_.length` must be equal to `_permissions.length`                             |
| `0x0011`     | `_signatures.length` must be equal to `_signers.length`                          |