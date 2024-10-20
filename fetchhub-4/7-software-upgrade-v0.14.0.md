
# Software upgrade

This guide is describing the procedure to upgrade to the [{==> CHANGE ME! <==} v0.14.0-rc9](https://github.com/fetchai/fetchd/releases/tag/v0.14.0-rc9) following the [{==> CHANGE ME! <==} CUDOS mainnet migration #32](https://www.mintscan.io/fetchai/proposals/32) software upgrade governance proposal.

We kindly ask all the validators to read through the following document, and then wait until chain reaches upgrade block height `{==> CHANGE ME! <==}` *before* executing the upgrade steps.

In case of questions or issues, feel free to reach me on Discord (`@v0id.ptr`), or Telegram [@v0idptr](https://t.me/v0idptr).

## About the upgrade

The primary feature of this release is merge of CUDOS network in to Fetch network (detailed description of the feature is provided in the [ {==> CHANGE ME! <==} PR #XXX @ YYY](https://github.com/fetchai/CHANGE_ME)).
In this release, the Municipal Inflation is configured for the MOBX (3% APR) and NOMX (3% APR) tokens.

The secondary features are:
 * Reconciliation,
 * Cleanup of `Almanac` and `AName` contracts
 * Setting admin for `Reconciliation` and `TokenBridge` contracts 
 * Setting label for `Reconciliation` contract
 * Setting cw2 contract version for `Reconciliation` contract

In principle this is breaking change upgrade, since it will change state of the chain = every node must upgrade, or at least sync from block height equal or higher than the upgrade height.
However, this upgrade does **not** change API whatsoever (static definition wise nor behavioural wise), since versions of underlying components (cosmos-sdk & tendermint) remains the same.

## Upgrade procedure

When mainnet blockchain reaches the target upgrade block height `{==> CHANGE ME! <==} 14699873`, validator nodes will halt - it is **\*expected\*** to have an error logged by the node, similar to:

```
{==> CHANGE ME! <==}
1:16PM ERR UPGRADE "v0.14.0" NEEDED at height: XXX: CUDOS mainnet migration v0.14.0 (upgrade-info)
1:16PM ERR CONSENSUS FAILURE!!! err="UPGRADE \"v0.14.0\" NEEDED at height: XXX"
```

Once this happens, node operators can proceed with installation of the new `v0.14.0` version of the `fetchd` executable.

## Install new fetchd version

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

# and verify you now have the correct version:
fetchd -h
# must print fetchd help message

fetchd version
# must print v0.14.0
```

Make sure the version is correct before proceeding further!

You're now ready to restart your node.

## Execute upgrade procedure steps

### Set primary environment variables
First define env variables which will be used in further commands below:
```shell
export DESTINATION_CHAIN_ID="fetchhub-4"
export GENESIS_FETCHUB_GIT_REVISION="v0.14.0"

{==> CHANGE ME! (HASH value) <==}

export UPGRADE_SHA256_PARAMS="--cudos-genesis-sha256 906ea6ea5b1ab5936bb9a5f350d11084eb92cba249e65e11c460ab251b27fb0e --cudos-migration-config-sha256 2c48a252a051fb90a6401dffb718892084047a3f00dc99481d3692063cf65cce"
```

### Set derived path env variables

```shell
export GENESIS_FETCHHUB_PATH="$FETCHD_HOME_DIR"/genesis-fetchhub
export UPGRADE_DATA_PATH="$GENESIS_FETCHHUB_PATH"/"$DESTINATION_CHAIN_ID"/data
```

### Download merge input files

Clone the correct version of  https://github.com/fetchai/genesis-fetchhub repository in to your `$FETCHD_HOME_DIR`
directory:
> **\*IF\*** the "$GENESIS_FETCHHUB_PATH" directory **\*exists already\***, please **delete it first** (if needed, backup it before deletion).
> ```shell
> rm -rf "$GENESIS_FETCHHUB_PATH"
> ```
```shell
git clone --branch $GENESIS_FETCHUB_GIT_REVISION --depth 1 https://github.com/fetchai/genesis-fetchhub "$GENESIS_FETCHHUB_PATH"
```

And finally **extract** the CUDOS genesis file:
```
7z e "$UPGRADE_DATA_PATH/genesis.cudos.json.7z" -o"$UPGRADE_DATA_PATH" 
```

### Confirm fetchd version
Confirm version of `fetchd` executable by executing following command:
```shell
fetchd version
```
> It **MUST** print `v0.14.0`. 

### Execute actual upgrade command
Then finally execute the upgrade - you **MUST** use the following commandline = the **VERY 1st** start of the **NEW**
`v0.14.0` version of `fetchd` node executable.
```shell
fetchd --home $FETCHD_HOME_DIR start --cudos-genesis-path $UPGRADE_DATA_PATH/genesis.cudos.json --cudos-migration-config-path $UPGRADE_DATA_PATH/cudos_merge_config.json $UPGRADE_SHA256_PARAMS
```
, where the `FETCHD_HOME_DIR` variable contains path to the home directory,
  and all following flags of the `start` command are **MANDATORY** (= **must** be provided) for the very 1st run of
  the new version `v0.14.0` of the `fetchd` executable = when upgrade procedure is actually executed:
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
{==> CHANGE ME! <==}
1:31PM INF applying upgrade "v0.14.0" at height: 14699873
```


> If there is an issue caused by using wrong input files (or hash values), the upgrade process will exit with
> appropriate error describing what specifically caused the failure. The upgrade procedure will **NOT** do any changes
> in node state **IF** the issue was caused by using wrong files or hash value = you can re-execute the upgrade again
> with correct files and hash values  should just hang and wait for more validators to complete

If input files and hashes are correct, your node starts executing the upgrade procedure which might take up anything
from 5 to 30 seconds, during which you should see lines, like the ones below, being printed in the log, indicating
progress of the upgrade procedure:

```log
{==> CHANGE ME! <==}

5:12AM INF cudos merge: loading merge source genesis json expected sha256=5751b1428d22471435940d93127675dfc14a287cfaa2fc87edf112a8050ff96c file=genesis.cudos.json
5:12AM INF cudos merge: loading network config expected sha256=8b0df35b60b4fdd459150a9674b9f07b5d9e79d51a7fa5f7e72bea179a1ca1b7 file=cudos_merge_config.json
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
5:12AM INF executed block height=14272900 module=consensus num_invalid_txs=0 num_valid_txs=0
```

After this point, node is just waiting until enough validators have upgraded & joined the network (with at least 2/3
of the global stake), after which the mainnet consensus will resume block generation on its own, and the mainnet
upgrade procedure is finished from the conceptual standpoint.

### Verify upgrade completed

You can now query your **local** RPC endpoint to verify that the right version is running and the node properly
restarted:

```bash
{==> CHANGE ME! <==}

curl -s http://localhost:26657/abci_info | jq -r '.result.response.version'
v0.14.0
```

> Make sure this print exactly the `v0.14.0` version. If not, double check you're on the right git tag in the `fetchd`
repository, that the `make install` didn't produce errors, and that your properly restarted your node.
