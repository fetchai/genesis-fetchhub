
# Software upgrade

> :exclamation: This guide is for **\*PRIVATE\*** Mainnet merge test.
> It takes the CUDOS mainnet [genesis.cudos.json.gz](data/genesis.cudos.json.gz) file has been exported at the
> `12332095` block height (block timestamp after the block execution is `2024-10-24T12:09:12.036983053Z`).
> 
> :exclamation: The [cudos_merge_config.json](data/cudos_merge_config.json) is copy of the production mainnet one
> [cudos_merge_config.json](../fetchhub-4/data/cudos_merge_config.json) (git commit 
> `273466d605dc026372baf01a5f95485588210eab`), and it has been modified to reflect that fact, that private mainnet has
> different set of active validators then production grade mainnet.

This guide is describing the procedure to upgrade to the [v0.14.0-rc17](https://github.com/fetchai/fetchd/releases/tag/v0.14.0-rc17)
following the "Cudos migration private test (#34)" software upgrade governance proposal, with halt height `18885253`.
Run the following command to query the full proposal data:
```shell
fetchd query gov proposal 34
```

We kindly ask all the validators to read through the following document, and then wait until chain reaches upgrade block height `18885253` *before* executing the upgrade steps.

In case of questions or issues, feel free to reach me on Discord (`@v0id.ptr`), or Telegram [@v0idptr](https://t.me/v0idptr).

## About the upgrade

The primary feature of this release is merge of CUDOS network in to Fetch network.

The secondary features are:
 * Reconciliation,
 * Cleanup of `Almanac` and `AName` contracts
 * Setting admin for `Reconciliation` and `TokenBridge` contracts 
 * Setting label for `Reconciliation` contract
 * Setting cw2 contract version for `Reconciliation` contract

In principle this is breaking change upgrade, since it will change state of the chain = every node must upgrade, or at least sync from block height equal or higher than the upgrade height.
However, this upgrade does **not** change API whatsoever (static definition wise nor behavioural wise), since versions of underlying components (cosmos-sdk & tendermint) remains the same.

## Upgrade procedure

When blockchain reaches the target upgrade block height `18885253`, all nodes will halt - it is **\*expected\*** to
have an error logged by the node, similar to:
```
1:16PM ERR UPGRADE "v0.14.0" NEEDED at height: 18885253: CUDOS mainnet migration v0.14.0 (upgrade-info)
1:16PM ERR CONSENSUS FAILURE!!! err="UPGRADE \"v0.14.0\" NEEDED at height: 18885253"
```

Once this happens, node operators can proceed with installation of the new `v0.14.0-rc17` version of the `fetchd` executable.

## Install new fetchd version

You may already have the fetchd repository on your machine from the previous installation. If not, you can:

```bash
git clone --branch v0.14.0-rc17 https://github.com/fetchai/fetchd fetchd_v0.14.0-rc17
cd fetchd_v0.14.0-rc17
```

If you already have an existing clone, place yourself in and:

```bash
git fetch
git clean -fd
git checkout v0.14.0-rc17
```

Now you can install the new `fetchd` version:

```bash
make install

# and verify you now have the correct version:
fetchd -h
# must print fetchd help message

fetchd version
# MUST print v0.14.0-rc17
```

Make sure the version is correct before proceeding further!

You're now ready to restart your node.

## Execute upgrade procedure steps

### Set primary environment variables
First define env variables which will be used in further commands below.

> :exclamation: Variables set in this section determine which upgrade you are going to do.

> :exclamation: Please **\*VERIFY\*** value of the `FETCHD_HOME_DIR` variable below and adjust it to correct directory
> of **\*your\*** node **\*IF\*** it differs from default!
```shell
# Please do *NOT* enclose value of this variable with double quotes, or with any quotation characters:
export FETCHD_HOME_DIR=~/.fetchd
```

```shell
export DESTINATION_CHAIN_ID="fetchhub-cudos-test-4"
export GENESIS_FETCHUB_GIT_REVISION="heads/cudos-merger-private-mainnet-test"
export UPGRADE_SHA256_PARAMS="--cudos-genesis-sha256 d90c131938493ade36ac727dfbdd21a43583903fcf2fedf1fb91b74eec432eb7 --cudos-migration-config-sha256 f0c48288ecb368b59429c8c7b3d2ec73efe49047cf25f4f21d944b92d357112b"
```

### Download merge input files

```shell
curl https://raw.githubusercontent.com/fetchai/genesis-fetchhub/refs/$GENESIS_FETCHUB_GIT_REVISION/fetchhub-cudos-test-4/data/cudos_merge_config.json -o "$FETCHD_HOME_DIR/cudos_merge_config.json"
curl https://raw.githubusercontent.com/fetchai/genesis-fetchhub/refs/$GENESIS_FETCHUB_GIT_REVISION/fetchhub-cudos-test-4/data/genesis.cudos.json.gz -o "$FETCHD_HOME_DIR/genesis.cudos.json.gz"
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
> It **MUST** print `v0.14.0-rc17`. 

### Execute actual upgrade command
Then finally execute the upgrade - you **MUST** use the following commandline = the **VERY 1st** start of the **NEW**
`v0.14.0-rc17` version of `fetchd` node executable.
```shell
fetchd --home "$FETCHD_HOME_DIR" start --cudos-genesis-path "$FETCHD_HOME_DIR/genesis.cudos.json" --cudos-migration-config-path "$FETCHD_HOME_DIR/cudos_merge_config.json" $UPGRADE_SHA256_PARAMS
```
, where the `FETCHD_HOME_DIR` variable contains path to the home directory,
  and all following flags of the `start` command are **MANDATORY** (= **must** be provided) for the very 1st run of
  the new version `v0.14.0-rc17` of the `fetchd` executable = when upgrade procedure is actually executed:
* `--cudos-genesis-path <PATH_TO_CUDOS_GENESIS_JSON_FILE>`
* `--cudos-migration-config-path <PATH_TO_CUDOS_MERGE_CONFIG_JSON_FILE>`
* `--cudos-genesis-sha256 <HASH>`
* `--cudos-migration-config-sha256 <HASH>`
Once the upgrade was successfully executed, flags mentioned above will be **IGNORED** and so the `fetchd start` command
can be run without providing them.

:exclamation: The `--cudos-genesis-sha256 <HASH>` and `--cudos-migration-config-sha256 <HASH>` flags with their
respective HASH values are very **IMPORTANT** - you **MUST** use the **VERY SAME** files and hash values as provided
in this documentation, especially hash values, since these will ensure, that you are using the correct input files
during the upgrade. 
> :exclamation: :no_entry_sign: Please do **NOT** derive hash values on your own from input files, and then use these
> instead of the ones we provide in this documentation, since that will allow your node to execute the upgrade using
>  **DIFFERENT** input files then rest of the nodes in the network, and almost certainly cause your node to  end up
> with different state then rest of the network after the upgrade, what effectively disqualify your node from
> reconnecting with the rest of the network, when the network will resume the consensus.


The line, like the one right below, must appear in the log, indicating that you are running the correct version of the
`fetchd` node executable.

```
1:31PM INF applying upgrade "v0.14.0" at height: 18885253
```


> If there is an issue caused by using wrong input files (or hash values), the upgrade process will exit with
> appropriate error describing what specifically caused the failure. The upgrade procedure will **NOT** do any changes
> in node state **IF** the issue was caused by using wrong files or hash value = you can re-execute the upgrade again
> with correct files and hash values  should just hang and wait for more validators to complete

If input files and hashes are correct, your node starts executing the upgrade procedure which might take up anything
from 5 to 30 seconds, during which you should see lines, like the ones below, being printed in the log, indicating
progress of the upgrade procedure:
```log
5:12AM INF cudos merge: loading merge source genesis json expected sha256=d90c131938493ade36ac727dfbdd21a43583903fcf2fedf1fb91b74eec432eb7 file=genesis.cudos.json
5:12AM INF cudos merge: loading network config expected sha256=f0c48288ecb368b59429c8c7b3d2ec73efe49047cf25f4f21d944b92d357112b file=cudos_merge_config.json
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
5:12AM INF executed block height=18885253 module=consensus num_invalid_txs=0 num_valid_txs=0
```

After this point, node is just waiting until enough validators have upgraded & joined the network (with at least 2/3
of the global stake), after which the mainnet consensus will resume block generation on its own, and the mainnet
upgrade procedure is finished from the conceptual standpoint.

### Verify upgrade completed

You can now query your **local** RPC endpoint to verify that the right version is running and the node properly
restarted:

```bash
curl -s http://localhost:26657/abci_info | jq -r '.result.response.version'
v0.14.0-rc17
```

> Make sure this print exactly the `v0.14.0-rc17` version. If not, double check you're on the right git tag in the `fetchd`
repository, that the `make install` didn't produce errors, and that your properly restarted your node.
