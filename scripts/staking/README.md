# Staked tokens collection script

Export currently staked ERC20 tokens with calculated compound interest. Also compute the fetch address from the ETH public key.

## Requirements

- node >= v16.0
- Infura Ethereum API project ID [https://infura.io/dashboard/ethereum](https://infura.io/dashboard/ethereum)

> The free tier account on Infura is enough for exporting the data, the script needs ~8200 API request from the 100k quota.

## Collect staked tokens

First, create a `.infura_project_id` file in this folder, with your Infura Ethereum API project ID in it.
Then execute:

```bash
# install dependencies
npm install

# collect staked tokens and accounts
node collect_staked.js > staked_export.csv
```

This will run for *~25 minutes*, and create a `staked_export.csv` file will all currently staked tokens and accounts.

The CSV file will contains the following fields on each line:

```
USER ADDRESS, USER PUBKEY, USER FETCH ADDRESS, TOTAL[afet], PRINCIPAL WHOLE[afet], COMPOUND INTEREST(LIQUID + LOCKED + STAKED)[afet]
```

Keep this `staked_export.csv` file path as this will be the input required to add the genesis delegations later.

You can verify you have the correct file by hashing it and comparing with our provided hash. Remember to sort it first.

```bash
cat staked_export.csv | sort | sha256sum
```
