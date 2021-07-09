# Stargate migration test

This repository contains steps and documentation aimed to **current mainnet validators** in order to repeat migrating their nodes and upgrade the network the Stargate version.


Validators can have a review on this repo docs and scripts, this should give a good idea what will happen. 
We'll still need to update few placeholders once we'll have the network ready to migrate but that's it.

In case of questions or issues, feel free to reach me on discord (@daeMOn).

# Timeline

## Starting from now

1) Create validators running on Launchpad testnet: https://docs.fetch.ai/ledger_v2/networks/#testnet-v2-fetchhubtest
    > The faucet now gives 1TESTFET, should be easy to get enough funds to proceed
    > There's some block history to catch up, so syncing may take a while

## On Thursday July, 15th

2) Agree on some block height to stop the network
3) Share the repo with the migration docs & scripts, adapted to this network
> The migration repo include an extract of ERC20 staked tokens we made, that we will import as TESTFET on the migrated test network.
> 

4) Everyone migrate their validator

## On Friday, July, 16th

5) Restart the migrated test network - ensure everything works fine. 

# Post migration

We're expecting validators to keep their test node running a little while, to give a chance to fetch users having their stake migrated to verify they can access properly their funds on testnet. But we'll then proceed with mainnet migration, and those test nodes can then be salvaged.
