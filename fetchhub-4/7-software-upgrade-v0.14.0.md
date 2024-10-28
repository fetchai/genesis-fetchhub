
# Software upgrade
This guide is describing the procedure to upgrade to the [v0.14.0](https://github.com/fetchai/fetchd/releases/tag/v0.14.0) following the [#33. CUDOS mainnet migration](https://www.mintscan.io/fetchai/proposals/33) software upgrade governance proposal.

We kindly ask all the validators to read through the following document, and then wait until chain reaches upgrade block height `18938999` *before* executing the upgrade steps.

In case of questions or issues, feel free to reach me on Discord (`@v0id.ptr`), or Telegram [@v0idptr](https://t.me/v0idptr).

This upgrade uses eternal CUDOS mainnet genesis file as input - it was exported from CUDOS mainnet at height `12385628`, sha256 of the file is `5eec16016006524b40f7777dece37ad07e3a514c20718e9cf0dca3082693e74b`.

# About the upgrade

The primary feature of this release is merge of the CUDOS mainnet in to the Fetch mainnet.

The secondary features are:
 * Reconciliation,
 * Cleanup of `Almanac` and `AName` contracts
 * Setting admin for `Reconciliation` and `TokenBridge` contracts 
 * Setting label for `Reconciliation` contract
 * Setting cw2 contract version for `Reconciliation` contract

In principle, this is breaking change upgrade, since it will change state of the chain = every node must upgrade, or at least sync from block height equal or higher than the upgrade height.
However, this upgrade does **not** change API whatsoever (static definition wise nor behavioural wise), since versions of underlying components (cosmos-sdk & tendermint) remains the same.

# Pre-requisites

In order o execute the upgrade successfully, required amount of hardware resources (mainly memory) will depend on
the amount of data node has in its storage (in the `~/.fetchd` directory, and there in particular the `data` and
`wasm` directories, where the `data` plays the primary role):

1. up to 500GB: at least 16GB memory and 2 CPU cores
2. 500GB to 1TB: at least 24GB memory and 2 CPU cores
3. above 1TB: at least 32GB memory and 2 CPU cores

> Run the following command to determine the amount of data of the node (command below **\*requires\*** the
> `FETCHD_HOME_DIR` env variable from the [Set primary environment variables](#set-primary-environment-variables)
> section to be set as node home dir):
> ```shell
> du -sh $FETCHD_HOME_DIR
> ```

# Upgrade procedure

## Wait for chain to halt 
When mainnet blockchain reaches the target upgrade block height `18938999`, validator nodes will halt - it is **\*expected\*** to have an error logged by the node, similar to:

```
1:16PM ERR UPGRADE "v0.14.0" NEEDED at height: 18938999: CUDOS mainnet migration v0.14.0 (upgrade-info)
1:16PM ERR CONSENSUS FAILURE!!! err="UPGRADE \"v0.14.0\" NEEDED at height: 18938999"
```

Once this happens, node operators can proceed with installation of the new `v0.14.0` version of the `fetchd` executable.

## Install new fetchd version
You can either build `fetchd` executable locally, or use the docker image:  

### Local build: 
You may already have the fetchd repository on your machine from the previous installation. If not, you can:

```bash
git clone --branch v0.14.0 https://github.com/fetchai/fetchd fetchd_v0.14.0
cd fetchd_v0.14.0
```

If you already have an existing clone, place yourself in and:

```bash
git fetch
git clean -fd
git checkout v0.14.0
```

Now you can install the new `fetchd` version:

```bash
make install

fetchd version
# must print v0.14.0
```

Make sure the version is correct before proceeding further!

### Docker image
Please use the `fetchai/fetchd:0.14.0` docker image, it is available on Docker Hub.

## Backup your node (**\*not\*** mandatory, but recommended)
Backup is not mandatory, though if something goes sideways, it will give you ability to revert to the state when
the mainnet halted.

:exclamation: Before doing this step, it is necessary to consider the amount of data nodes has in its home dir,
since backup might take considerable amount of time and disk space.
The `du` command output from the [Pre-requisites](#pre-requisites) section will serve as the guide.

If decided to go ahead with the backup, below is the backup command (it **\*requires\*** the `FETCHD_HOME_DIR` env
variable from the [Set primary environment variables](#set-primary-environment-variables) section to be set):
```shell
tar cf $FETCHD_HOME_DIR/node_backup.tar -C $FETCHD_HOME_DIR --exclude=wasm/wasm/cache config data wasm
```

## Execute upgrade procedure steps

### Set primary environment variables
First define env variables which will be used in further commands below.

> :warning: Please **\*VERIFY\*** value of the `FETCHD_HOME_DIR` variable below and adjust it to correct directory
> of **\*your\*** node **\*IF\*** it differs from default!
>
> :warning: If you need to use quotes "..." in a value of the env var below, and at the same time the ~ (tilde
> expansion variable), please do **\*not\*** include the ~ tilde expansion character in between quotes.
```shell
export FETCHD_HOME_DIR=~/.fetchd
```

```shell
export DESTINATION_CHAIN_ID="fetchhub-4"
export GENESIS_FETCHHUB_GIT_REVISION="tags/v0.14.0"

{==> CHANGE ME! (HASH value) <==}

export UPGRADE_SHA256_PARAMS="--cudos-genesis-sha256 5eec16016006524b40f7777dece37ad07e3a514c20718e9cf0dca3082693e74b --cudos-migration-config-sha256 e1631e27629f9e32a5ec6c8fdd56d0d8ec31d7cd6b6a5e2662ce107b56f623ee"
```


### Download merge input files

```shell
curl https://raw.githubusercontent.com/fetchai/genesis-fetchhub/refs/$GENESIS_FETCHHUB_GIT_REVISION/fetchhub-4/data/cudos_merge_config.json -o "$FETCHD_HOME_DIR/cudos_merge_config.json"
curl https://raw.githubusercontent.com/fetchai/genesis-fetchhub/refs/$GENESIS_FETCHHUB_GIT_REVISION/fetchhub-4/data/genesis.cudos.json.gz -o "$FETCHD_HOME_DIR/genesis.cudos.json.gz"
```

And finally **extract** the CUDOS genesis file:
```shell
gzip -d -c "$FETCHD_HOME_DIR/genesis.cudos.json.gz" > "$FETCHD_HOME_DIR/genesis.cudos.json"
```

### Confirm fetchd version
Confirm version of `fetchd` executable by executing following command:
```shell
fetchd version
```
> :exclamation: It **MUST** print `v0.14.0`.

### Execute actual upgrade command
Then finally execute the upgrade - the following commandline **\*must\*** be used for the **\*very 1st\*** start of the
**\*new\*** `v0.14.0` version of `fetchd` node executable.

:warning: Before you execute this command, please read the description provided below the command.

```shell
fetchd --home "$FETCHD_HOME_DIR" start --cudos-genesis-path "$FETCHD_HOME_DIR/genesis.cudos.json" --cudos-migration-config-path "$FETCHD_HOME_DIR/cudos_merge_config.json" $UPGRADE_SHA256_PARAMS
```

> :warning: We do **\*NOT\*** recommend changing the command above!
> 
> The `FETCHD_HOME_DIR` variable contains path to the home directory of your node, and all flags following the
> `start` command are **MANDATORY** (= **must** be provided) for the **\*very 1st\*** run of the new version `v0.14.0`
> of the `fetchd` executable = when upgrade procedure is actually executed:
> * `--cudos-genesis-path <PATH_TO_CUDOS_GENESIS_JSON_FILE>`
> * `--cudos-migration-config-path <PATH_TO_CUDOS_MERGE_CONFIG_JSON_FILE>`
> * `--cudos-genesis-sha256 <HASH>`
> * `--cudos-migration-config-sha256 <HASH>`
>
> Once the upgrade was successfully executed, flags mentioned above will be **\*ignored\*** and so the `fetchd start`
> command can be run without providing them, or with them, they will not matter anymore.
>
> :warning: The `--cudos-genesis-sha256 <HASH>` and `--cudos-migration-config-sha256 <HASH>` flags with their
> respective HASH values are very **IMPORTANT** - you **MUST** use the **VERY SAME** files and hash values as provided
> in this documentation, especially hash values, since these will ensure, that you are using the correct input files
> during the upgrade.
>
> :no_entry_sign: Please do **NOT** derive hash values on your own from input files, and then use these
> instead of the ones we provide in this documentation, since that will allow your node to execute the upgrade using
> **DIFFERENT** input files then the rest of the nodes in the network, and almost certainly cause your node to end up
> with different state then the rest of the network after the upgrade, what effectively disqualify your node from
> joining the network, when it will resume the consensus.
> 
> If hashes from input files do not match ones provided at command-line, the upgrade process will exit with appropriate
> error describing what specifically caused the failure, without performing any changes in node state = the upgrade
> procedure can be re-executed again with correct files and hash values.

The line, like the one right below, must appear in the log, indicating that you are running the correct version of the
`fetchd` node executable.

```
1:31PM INF applying upgrade "v0.14.0" at height: 18938999
```

If input files and hashes are correct, your node starts executing the upgrade procedure, which might take anything
from 1 minute up to 1 hour, depending on amount of data node has in its DBs, and hardware where node upgrade is being
executed (mainly disk speed, number of CPUs and memory). During the execution you should see lines like the ones below
being printed in the log, indicating progress of the upgrade procedure:

```log
{==> CHANGE ME! <==}

5:12AM INF cudos merge: loading merge source genesis json expected sha256=5eec16016006524b40f7777dece37ad07e3a514c20718e9cf0dca3082693e74b file=genesis.cudos.json
5:12AM INF cudos merge: loading network config expected sha256=e1631e27629f9e32a5ec6c8fdd56d0d8ec31d7cd6b6a5e2662ce107b56f623ee file=cudos_merge_config.json
5:12AM INF cudos merge: remaining bonded pool balance amount=183acudos
5:12AM INF cudos merge: remaining not-bonded pool balance amount=6241acudos
5:12AM INF cudos merge: remaining dist balance amount=51acudos
```

Once you see the lines like below being printed in the log, the upgrade procedure **has finished**:
```log
5:12AM INF minted coins from module account amount=88946755672000000000000000atestfet from=mint module=x/bank
5:12AM INF minted coins from module account amount=480989277nanomobx from=mint module=x/bank
5:12AM INF minted coins from module account amount=4795384342nanonomx from=mint module=x/bank
5:12AM INF minted coins from module account amount=6296428529541965571atestfet from=mint module=x/bank
5:12AM INF executed block height=18938999 module=consensus num_invalid_txs=0 num_valid_txs=0
```

After this point, node is just waiting until enough validators have upgraded & joined the network (with at least 2/3
of the global stake), after which the mainnet consensus will resume block generation on its own, and the mainnet
upgrade procedure is finished from the conceptual standpoint.

### Verify upgrade completed

You can now query your **local** RPC endpoint to verify that the right version is running and the node properly
restarted:

```bash
curl -s http://localhost:26657/abci_info | jq -r '.result.response.version'
v0.14.0
```

> Make sure this print exactly the `v0.14.0` version. If not, double check you're on the right git tag in the `fetchd`
repository, that the `make install` didn't produce errors, and that your properly restarted your node.
