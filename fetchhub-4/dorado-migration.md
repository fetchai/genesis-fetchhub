# Dorado migration

This document describe the steps needed in order to upgrade a validator node running on `fetchd v0.9.x` to the `fetchd v0.10.2` version.
It is **advised to read the whole document before starting applying this procedure**, in order to avoid your validator node being unable to restart.
In case anything is unclear or if you have any questions, feel free to reach us out or ask in the Discord #mainnet channel.

This upgrade mostly aim on upgrading the network genesis to:
- support cosmos-sdk v0.45.1
- support ibc-go v2.2.0
- support wasmd v0.24
- mint a new `nanonomx` token
- mint a new `ulrn` token

## Before starting

### Get familiar with the new version

This time, the Dorado upgrade doesn't introduce many changes on `fetchd` itself. The main breaking change is comming from ibc-go new version and the new cosmos-sdk version. You can test this new version by following the install instructions for the [`fetchd v0.10.2` version](https://github.com/fetchai/fetchd/releases/tag/v0.10.2) and interact with our `Dorado` testnet (get the connections settings on [our networks documentation page](https://docs.fetch.ai/ledger_v2/networks/)). 

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

We'll use a dedicated discord channel (`#mainnet`) for the migration, where we'll share important information such as the block height we'll stop at, or validating `sha256sum` of the genesis file at each steps. Make sure to join it! This repository will also get updated on the way with all the necessary informations to validate a node migration.

## Stop your validator

First, make sure your node have reached at least the `5300200` block height we will use to export the network state and restart from. You can configure your node in advance to stop at this height by setting the `halt-height` parameter in the `app.toml` file and restarting your node.
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
fetchd --home ~/.fetchd/ export --height 5300200 > genesis_export_5300200.json
```

Generate a hash of this file and validate it with others:

```bash
sha256sum genesis_export_5300200.json
```

> Expected hash `e0df0ea9b073828047afef06681b4f3f2d7f8857c71b478b2a0ecf1684f77736`
> File available at [./data/genesis_export_5300200.json](./data/genesis_export_5300200.json)

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
git clone --branch v0.10.2 https://github.com/fetchai/fetchd.git fetchd_0.10.2
cd fetchd_0.10.2
```

If you already have an existing clone, place yourself in and:

```bash
git fetch
git checkout v0.10.2
```

Now you can install the new fetchd version:

```bash
make install

# and verify you now have the correct version:
fetchd -h
# must print fetchd help message

fetchd verion
# must print v0.10.2
```

## Migrate genesis

Now we have the new version of `fetchd`, we're ready to upgrade the genesis file to Dorado:

```bash
fetchd --home ~/.fetchd/ dorado-migrate \
    --genesis-time "2022-04-05T16:00:00Z" \
    genesis_export_5300200.json > genesis_migrated_5300200.json
```

We're setting here the time when the network will restart. 
The new chainID, initial block number and other important parameters are automatically set by the dorado-migrate command via their default values.

Again, we'll hash the created genesis and ensure it matches the expected hash with other people:

```bash
sha256sum genesis_migrated_5300200.json
```

> Expected hash `TODO_STEP2_HASH`
> File available at [./data/genesis_migrated_5300200.json](./data/genesis_migrated_5300200.json)

## Restart your node

You're now ready to restart your fully migrated node!

### Caution!

- To avoid errors here, make sure to wait for a confirmation on Discord from me (@daeMOn#5105) that the seeds are up and running. Otherwise, unexpected startup errors might occur.

- If you have set a halt-height in your FETCHD_HOME/config/app.toml earlier to stop your node, remember to retore it to `halt-height = 0` to allow your node to start!


Run:

```bash
fetchd --home ~/.fetchd/ start --p2p.seeds 17693da418c15c95d629994a320e2c4f51a8069b@connect-fetchhub4.m-v2-london-c.fetch-ai.com:36456,a575c681c2861fe945f77cb3aba0357da294f1f2@connect-fetchhub4.m-v2-london-c.fetch-ai.com:36457,d7cda986c9f59ab9e05058a803c3d0300d15d8da@connect-fetchhub4.m-v2-london-c.fetch-ai.com:36458
```

If you did not configure yet a `min-gas-prices` in your `app.toml` configuration, you will see the following warning message on startup:

```
4:50PM ERR WARNING: The minimum-gas-prices config in app.toml is set to the empty string. This defaults to 0 in the current version, but will error in the next version (SDK v0.45). Please explicitly put the desired minimum-gas-prices in your app.toml.
```

This is fine and can be ignored, or you're free to set a `min-gas-prices` to a value of your choice for now. We'll reach out to you in a near future to discuss about the `min-gas-prices` setting.

> If you have errors at launch, first try to `fetchd --home ~/.fetchd/ unsafe-reset-all` first and restart. If no changes, reach out on Discord for help!

After starting, some messages will be printed in the console, and no activity will happen until 2/3 of the voting power come back online. When enough validators are online, you should see some activity in logs with messages like:

```
8:40AM INF executed block height=XYZ module=state num_invalid_txs=0 num_valid_txs=0
```

Meaning we're back producing blocks on the new network.