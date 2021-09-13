# Stargate migration

This document describe the steps needed in order to upgrade a validator node running on `fetchd v0.7.x` to the `fetchd 0.8.7`.
It is **advised to read the whole document before starting applying this procedure**, in order to avoid your validator node being unable to restart.
In case anything is unclear or if you have any questions, feel free to reach us out or ask in the Discord #validator channel.

## Before starting

### Get familiar with the new version

The stargate upgrade introduce many changes in the application, most notably, the `fetchcli` binary have disappeared, and all its commands can now be ran on `fetchd` directly. You can test this new version by following the install instructions for the `fetchd 0.8.7` and interact with our `stargateworld` testnet (get the connections settings on [our networks documentation page](https://docs.fetch.ai/ledger_v2/networks/)).

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

First, make sure your node have reached at least the `2436700` block height we will use to export the network state and restart from. You can configure your node in advance to stop at this height by setting the `halt-height` parameter in the `app.toml` file and restarting your node.
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
fetchd --home ~/.fetchd/ export --height 2436700 > genesis_export_2436700.json
```

Generate a hash of this file and validate it with others:

```bash
sha256sum genesis_export_2436700.json
```

> Expected hash `TODO_HASH_TBA`
> File available at `TODO_EXPORTED_GENESIS_TBA`

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
git clone --branch v0.8.7 https://github.com/fetchai/fetchd.git fetchd_0.8.7
cd fetchd_0.8.7
```

If you already have an existing clone, place yourself in and:

```bash
git fetch
git checkout v0.8.7
```

Now you can install the new fetchd version:

```bash
make install

# and verify you now have the correct version:
fetchd -h
# must print fetchd help message
```

## Update configuration

Configuration files received a lot of updates between versions, with quite a few new keys, and a couple of modified values on existing keys. The easiest way to update is to drop the existing configuration and integrate back your previous changes on top of the freshly generated config.

```bash
# safe to drop existing configs since we have made backups earlier
rm ~/.fetchd/config/app.toml ~/.fetchd/config/config.toml

# fetchd will detect missing config files and regenerate new ones
fetchd version
# must print `0.8.7`
```

Now you can edit `~/.fetchd/config/app.toml` and `~/.fetchd/config/config.toml` to add back any changes you made previously, or have a look at all the new settings.

> You'll need to at least set your `moniker` back in `~/.fetchd/config/config.toml`.

> The new configuration include a lots of new comments and descriptions of the parameters, so worth reviewing them in any cases.

## Migrate genesis

Now the new version of `fetchd` have proper configuration, we're ready to upgrade the genesis file to Stargate:

```bash
fetchd --home ~/.fetchd/ stargate-migrate \
    --chain-id fetchhub-2 \
    --genesis-time 2021-09-16T14:00:00Z \
    --initial-height 2440501 \
    genesis_export_2436700.json > ~/.fetchd/config/genesis.json
```

We're setting here the new chainID, the time where the network will restart, and the initial block number.

Again, we'll hash the created genesis and ensure it matches the expected hash with other people:

```bash
sha256sum ~/.fetchd/config/genesis.json
```

> Expected hash `TODO_HASH_TBA`

Next, we'll introduce some changes in the genesis before restarting, to include MOBX tokens and migrate staked ERC20 tokens.

### Add MOBX genesis account

```bash
fetchd --home ~/.fetchd/ add-genesis-account TODO_MOBX_GENESIS_ACCOUNT 100000000000000000nanomobx
```

> Expected hash `TODO_HASH_TBA`

### Migrate staked ERC20 tokens

To ease the migration, we've extracted the staked ERC20 accounts and tokens into the [staked_erc20.csv file](./data/staked_export.csv). However, you can still replay the generation of this file and verify our scripts if you'd want to, by checking the [staking](./scripts/staking/) folder which contains the code and instructions needed.

To add the delegations to the genesis file, run:

```bash
git clone https://github.com/fetchai/genesis-fetchhub.git

cd genesis-fetchhub/

# make sure you're on branch `main`

# this script requies gawk
sudo apt-get update && sudo apt-get install -y gawk

FETCHD_HOME=~/.fetchd/ ./scripts/import_staked.sh ./data/staked_export.csv
```

> If you opted to regenerate the staked_export.csv youself, make sure to replace it with your own path above.

Again, ensure everything went well hashing the genesis and verify it matches the expected hash with other people:

```bash
sha256sum ~/.fetchd/config/genesis.json
```

> Expected hash here: `TODO_HASH_TBA`

If needed, the final genesis is available in `TODO_MIGRATED_GENESIS_TBA`

## Restart your node

You're now ready to restart your fully migrated node!

Run:

```bash
fetchd --home ~/.fetchd/ start --p2p.seeds TODO_STARGATE_MAINNET_SEEDS
```

> If you have errors at launch, first try to `fetchd --home ~/.fetchd/ unsafe-reset-all` first and restart. If no changes, reach out on Discord for help!

After starting, some messages will be printed in the console, and no activity will happen until 2/3 of the voting power come back online. When enough validators are online, you should see some activity in logs with messages like:

```
8:40AM INF executed block height=XYZ module=state num_invalid_txs=0 num_valid_txs=0
```

Meaning we're back producing blocks on the new network.

## Troubleshooting help

### CLI config

Fetch 0.8.x version has included all the fetchcli functionality inside the fetchd command, but as with fetchli it must be configured to point to the corresponding chain and node. So if you are getting errors when using old cli commands it may be misconfigured.

Error example:

```bash
fetchd query account ${your_fetch_account_hash}
Error: error unmarshalling result: unknown field "proof" in types.ResponseQuery
```

> Check your fetchd config

```bash
fetchd config
```

expected output should be something like the following

```json
{
  "chain-id": "fetchhub-2",
  "keyring-backend": "os",
  "output": "text",
  "node": "https://rpc-fetchhub.fetch.ai:443",
  "broadcast-mode": "sync"
}
```

if not config fetchd as you would with fetchcli

```bash
fetchd config chain-id fetchhub-2
fetchd config node https://rpc-fetchhub.fetch.ai:443
```

### Import your node keys

If your keys are not showing when listing them with the following command

```bash
fetchd keys list
```

you'll have to import them with the following command and provide the mnemonic phrase for the account to recover:

```bash
fetchd keys add ${your-key-name} --recover
```

\* Repeat the process for as many keys as you need to import

### KMS with tmkms library

If having the following error maybe caused by your kms server misconfigured due to the change of the network and the Tendermint version

```
Error:
Error: error with private validator socket client: can't get pubkey: send: endpoint connection timed out
```

Before migration Tendermint version was v0.33 and now it's v0.34, so it has to be changed. Changing chain-id identifier to fetchhub-2 may also be needed. And deleting the tmkms state file.

> Check Tendermint version (on your validator node)

```bash
fetchd tendermint version
```

```
tendermint: 0.34.11
abci: 0.17.0
blockprotocol: 11
p2pprotocol: 8
```

> Edit your tmkms config file tmkms.toml

```bash
vi tmkms/tmkms.toml
```

```
[[chain]]
id = "fetchhub-2"
...

[[providers.your_type_of_provider]]
// change the chain-id config if needed here also

[[validator]]
chain_id = "fetchhub-2"
...
protocol_version = "v0.34"
reconnect = true
```

> Also the Tmkms state file should be deleted to recreate a new one when the service is restarted.

```bash
rm ./your_tmks_service_folder/state/${your-consensus-file-name}.json
```

Restart your tmkms service and launch again your validator. A log like the one below should appear:

```
_Jul 15 16:12:40 your-host-name tmkms[40001]: 2021-07-15T16:12:40.402128Z INFO tmkms::session: [fetchhub-2@tcp://your-host-ip:your-host-port] connected to validator successfully_
```
