# Stargate migration

This repository contains steps and documentation aimed to **current mainnet validators** in order to migrate their nodes and upgrading the network to the Stargate version.


Validators can have a review on this repo docs and scripts, this should give a good idea what will happen. 
We'll still need to update few placeholders once we'll have the network ready to migrate but that's it.

In case of questions or issues, feel free to reach me on discord (@daeMOn).

# Timeline

## Pre migration

1) Share this repository with the mainnet validators
2) Replace and adjust the last remaining placeholders in the procedure (`TODO_` items)

## On Wednesday September, 15th

1) Pause the bridge contract
2) Stop the network at around 14:00 UTC (height: 2440500)
3) Begin migration, exporting genesis state from current mainnet
4) Export staked tokens CSV and upload the result to this repository
5) Finish the migration procedure and share hashes with the community

## On Thursday, September, 16th

1) Restart the migrated network at around 14:00 UTC
2) ensure everything works fine. 
