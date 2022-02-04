# Capricorn migration

This document describe the steps needed in order to upgrade a validator node running on `fetchd v0.8.x` to the `fetchd v0.9.0` version.
It is **advised to read the whole document before starting applying this procedure**, in order to avoid your validator node being unable to restart.
In case anything is unclear or if you have any questions, feel free to reach us out or ask in the Discord #validator channel.

This upgrade mostly aim on upgrading the network genesis to:
- enable IBC transfers
- lift wasm code-upload and instantiate restrictions we've had since network launch
- perform reconciliation of accounts unable to access their funds from the previous staking migration
- burn some foundation tokens that got mistakenly minted at the previous network upgrade event

as well as some minor cleanup and parameter tweaks:
- cleanup of unused foundation smart-contract code & state
- upgrade token bridge and mobix staking contracts to support Cosmwasm v1.0.0
- adjust mobix config unbonding_period from nanoseconds to seconds (due to unit change in contract code)
- increase slashing.params.slash_fraction_double_sign value
- increase consensus block max_bytes & max_gas & evidence max_bytes

## Before starting

### Get familiar with the new version

This time, the Capricorn upgrade doesn't introduce many changes on `fetchd` itself. The main breaking change is comming from the Cosmwasm new version. You can test this new version by following the install instructions for the [`fetchd v0.9.0` version](https://github.com/fetchai/fetchd/releases/tag/v0.9.0) and interact with our `Capricorn` testnet (get the connections settings on [our networks documentation page](https://docs.fetch.ai/ledger_v2/networks/)). 

### Exporting reconciliation data

The data from the reconciliation program will need to be exported **before** the network stop, and **after** the contract have been paused.
We will provide you the correct data on the migration day, but you are also able to generate them yourself following the instructions below.

> Note: the contract pause is currently planned on **Friday 4th Febuary @ 12:00 UTC**.

For exporting the data, you can clone this repository and run the following. This must be executed **with the current fetchd v0.8.7** version still installed.

```bash
./scripts/query_all_reconciliation_registrations.sh fetch1k0jntykt7e4g3y88ltc60czgjuqdy4c9gl50xa > ./reconciliation_export.json
sha256sum ./reconciliation_export.json
# must print TODO_EXPECTED_HASH
```

In case the contract is not yet paused, an error will be reported and the `./reconciliation_export.json` will be empty.

### Locate your files

Before starting, make sure to locate the following files on your validator host:

- **FETCHD_HOME**: folder containing all of the validator data. By default, the `fetchd` command will automatically create it under `~/.fetchd`, or in the location pointed by the `--home` flag on its first invocation if it doesn't exist.
- FETCHD_HOME/config/**node_key.json**: this file hold your node private key.
- FETCHD_HOME/config/**priv_validator_key.json**: this file hold your validator private key.
- FETCHD_HOME/config/**config.toml**: this is your node configuration
- FETCHD_HOME/config/**app.toml**: this configuration allows to tune the cosmos application, such as enabled apis, telemetry, pruning...
- FETCHD_HOME/config/**client.toml**: this file stores the client config, equivalent to the legacy `fetchcli config` which is now replaced by `fetchd config`.

> If needed, clone this repo and use the [./scripts/locate_home.sh](./scripts/locate_home.sh) script to help find the right folder, giving it your validator operator address and a search path:
>
> ```
> ./scripts/locate_home.sh fetchvaloper1fvcepqdw4lcc4s0gmxxfhkptyasfceg69x9gsc /home/
> ```
>
> (if no match, rerun it with `sudo` to allow it traversing directories owned by other users)

For the rest of the document, FETCHD_HOME is assumed to be at the default `~/.fetchd/` location. If your installation is different, replace `~/.fetchd/` path in all the commands with your actual `FETCHD_HOME` path.

### Join discord channel

We'll setup a dedicated discord channel for the migration, where we'll share important information such as the block height we'll stop at, or validating `sha256sum` of the genesis file at each steps. Make sure to join it!


## Stop your validator

First, make sure your node have reached at least the `TODO_STOP_BLOCK_HEIGHT` block height we will use to export the network state and restart from. You can configure your node in advance to stop at this height by setting the `halt-height` parameter in the `app.toml` file and restarting your node.
Also ensure that **no process managers (such as `systemd`) will attempt to restart it.**

The exact procedure to stop your node depends on how you configured it so we can't really give a generic way here.

Also double check it's properly stopped to avoid file corruption in the next steps.

## Backup FETCHD_HOME

Before making any changes, it's prefered to create a backup copy of your current `FETCHD_HOME` directory.

The following command can be used, assuming your `FETCHD_HOME` is `~/.fetchd/`:

```bash
cp -R ~/.fetchd/ ~/.fetchd_old/
```

This would allow to revert back to your starting state in case something goes wrong on the way.

## Export network state

```bash
fetchd --home ~/.fetchd/ export --height TODO_STOP_BLOCK_HEIGHT > genesis_export_TODO_STOP_BLOCK_HEIGHT.json
```

Generate a hash of this file and validate it with others:

```bash
sha256sum genesis_export_TODO_STOP_BLOCK_HEIGHT.json
```

> Expected hash `TODO_EXPECTED_HASH`
> File available at [./data/genesis_export_TODO_STOP_BLOCK_HEIGHT.json](./data/genesis_export_TODO_STOP_BLOCK_HEIGHT.json)

When your genesis hash matches the expected one, it's now time to update fetchd to the latest version.

## Reset the fetchd database

Now we have exported the state properly, we can drop the fetchd database:

> **Double check you have proper backups** of your FETCHD_HOME, and that the exported genesis is the correct one. `fetchd export` won't have anything to export anymore after this step!

```bash
fetchd --home ~/.fetchd/ unsafe-reset-all
```

## Install new fetchd version

You may already have the fetchd repository on your machine from the previous installation. If not, you can:

```bash
git clone --branch v0.9.0 https://github.com/fetchai/fetchd.git fetchd_0.9.0
cd fetchd_0.9.0
```

If you already have an existing clone, place yourself in and:

```bash
git fetch
git checkout v0.9.0
```

Now you can install the new fetchd version:

```bash
make install

# and verify you now have the correct version:
fetchd -h
# must print fetchd help message

fetchd verion
# must print v0.9.0
```

## Download updated smart contracts

With the new cosmwasm version, we have to update the token bridge and mobix staking contracts to allow them to run on the new VM engine.

For convenience, the new contracts have been pre-compiled and added to this repo (see [./data/contracts/](./data/contracts/)), and can be downloaded with:

```bash
curl https://raw.githubusercontent.com/fetchai/genesis-fetchhub/main/fetchhub-3/data/contracts/bridge.wasm --output ./bridge.wasm
sha256sum ./bridge.wasm
# must print ba4676a2f8ddf43d3d8ed7f12743b26885579422b96331690879202e6adfd27f

curl https://raw.githubusercontent.com/fetchai/genesis-fetchhub/main/fetchhub-3/data/contracts/mobix_staking.wasm --output ./mobix_staking.wasm
sha256sum ./mobix_staking.wasm
# must print TODO_NEW_MOBIX_CONTRACT_HASH
```

TODO_CONTRACT_BUILD_INFOS

## Migrate genesis

Now we have the new version of `fetchd` and the contract binaries, we're ready to upgrade the genesis file to Capricorn:

```bash
fetchd --home ~/.fetchd/ capricorn-migrate \
    --chain-id fetchhub-3 \
    --genesis-time TODO_NEW_GENESIS_TIME \
    --bridge-new-contract-path ./bridge.wasm \
    --mobix-new-contract-path ./mobix_staking.wasm \
    genesis_export_TODO_STOP_BLOCK_HEIGHT.json > genesis_migrated_TODO_STOP_BLOCK_HEIGHT.json
```

We're setting here the new chainID, the time when the network will restart, and the initial block number as well as the 2 contract paths.

Again, we'll hash the created genesis and ensure it matches the expected hash with other people:

```bash
sha256sum genesis_migrated_TODO_STOP_BLOCK_HEIGHT.json
```

> Expected hash `TODO_EXPECTED_HASH`
> File available at [./data/genesis_migrated_TODO_STOP_BLOCK_HEIGHT.json](./data/genesis_migrated_TODO_STOP_BLOCK_HEIGHT.json)

Once done, the contract files can be safely deleted from your filesystem

```bash
rm ./bridge.wasm ./mobix_staking.wasm 
```

## Migrate funds from reconciliation program

This 2nd step aim to migrate funds to users who have lost access to their funds and registered to our reconciliation program.

First, download the data files we'll need:

```bash
curl https://raw.githubusercontent.com/fetchai/genesis-fetchhub/main/fetchhub-3/data/staked_export.csv --output staked_export.csv
sha256sum staked_export.csv
# must print cbe48027309bd7969a7929bece94b4003819a3e0ed671d7e4bac6d265f7945e4

curl https://raw.githubusercontent.com/fetchai/genesis-fetchhub/main/fetchhub-3/data/reconciliation_export.json --output reconciliation_export.json
sha256sum reconciliation_export.json
# must print TODO_RECONCILIATION_EXPORT_HASH
```

Again, those files are only provided for convenience. You can generate them yourself.
- For the `staked_export.csv`, follow the instructions from previous migration at [../archive/fetchhub-2/scripts/staking/](../archive/fetchhub-2/scripts/staking/
- You must have created the `reconciliation_export.json`, following the [Exporting reconciliation data section](#exporting-reconciliation-data) at the begining of this document.

With those files, we can now run the reconciliation command and write the final genesis:

```bash
fetchd --home ~/.fetchd/ stake-reconciliation-migrate ./genesis_migrated_TODO_STOP_BLOCK_HEIGHT.json \
    --stakes-csv ./staked_export.csv \
    --registrations ./reconciliation_export.json > ~/.fetchd/config/genesis.json
```

> Expected hash `TODO_EXPECTED_HASH`
> File available at [./data/genesis.json](./data/genesis.json)

## Restart your node

You're now ready to restart your fully migrated node!

> Caution!

> To avoid errors here, make sure to wait for a confirmation on Discord from me (@daeMOn) that the seeds are up and running. Otherwise, unexpected startup errors might occur.

Run:

```bash
fetchd --home ~/.fetchd/ start --p2p.seeds 5f3fa6404a67b664be07d0e133a00c1600967396@connect-fetchhub3.m-v2-london-c.fetch-ai.com:36756,8272b70e1986e2080ca328309a5aad3bb932fcab@connect-fetchhub3.m-v2-london-c.fetch-ai.com:36757,81f479ad9b4b1d25bceedb2a13139187792442bf@connect-fetchhub3.m-v2-london-c.fetch-ai.com:36758
```

> If you have errors at launch, first try to `fetchd --home ~/.fetchd/ unsafe-reset-all` first and restart. If no changes, reach out on Discord for help!

After starting, some messages will be printed in the console, and no activity will happen until 2/3 of the voting power come back online. When enough validators are online, you should see some activity in logs with messages like:

```
8:40AM INF executed block height=XYZ module=state num_invalid_txs=0 num_valid_txs=0
```

Meaning we're back producing blocks on the new network.