
# Software upgrade

This guide is describing the procedure to upgrade to the [v0.14.1](https://github.com/fetchai/fetchd/releases/tag/v0.14.1) following the [Fix for the ASA-2025-004 vulnerability in IBC module (#45)](https://companion.fetch.ai/dorado-1/proposals/45) software upgrade governance proposal.

We kindly ask all the validators to read through the following document, and then wait until chain reaches upgrade block height defined in the gov proposal mentioned above *before* executing the upgrade steps.

In case of questions or issues, feel free to reach me on Discord (`@v0id.ptr`), or Telegram [@v0idptr](https://t.me/v0idptr).

# About the upgrade

The primary feature of this upgrade is fixing the ASA-2025-004 vulnerability in IBC module:
 * (`ibc-go`) [Merge the fix for the ASA-2025-004 vulnerability in IBC module #2](https://github.com/fetchai/ibc-go/pull/2)
 * (`fetchd`) [fix: ASA-2025-004 vulnerability in IBC module #419](https://github.com/fetchai/fetchd/pull/419)

The secondary feature is:
 * (`fetchd`) [feat: Support for importing unarmored key (secp256k1 & ed25519 algos) #417](https://github.com/fetchai/fetchd/pull/417)

In principle this should not be breaking change upgrade, since it shall not affect state of the chain.
Also, this upgrade does **not** change API whatsoever (static definition wise nor behavioural wise), since versions of underlying components (cosmos-sdk & tendermint) remains the same.

# Pre-requisites

## Set environment variables
We would suggest to set the following environment variable, since it is used in commands below:
> :warning: If you need to use quotes "..." in a value of the env var below **\*and\*** at the same time the ~ (tilde
> expansion variable), please do **\*not\*** include the ~ tilde expansion character in between quotes.
```shell
export FETCHD_HOME_DIR=~/.fetchd
```

# Upgrade procedure

## Chain halt
Wait until blockchain reaches the target upgrade block height `16915020`, at which point all nodes will halt - it is **\*expected\*** to have an error logged by the node, similar to:

```
11:27AM ERR UPGRADE "v0.14.1" NEEDED at height: 16915020: Fix for the ASA-2025-004 vulnerability in IBC module
11:27AM ERR CONSENSUS FAILURE!!! err="UPGRADE \"v0.14.1\" NEEDED at height: 16915020"
```

Once this happens, node operators can proceed with installation of the new `v0.14.1` version of the `fetchd` executable.

## Install new fetchd version
You can either build `fetchd` executable locally, or use the docker image:  

### Local build: 
You may already have the fetchd repository on your machine from the previous installation. If not, you can:

```bash
git clone --branch v0.14.1 https://github.com/fetchai/fetchd fetchd_v0.14.1
cd fetchd_v0.14.1
```

If you already have an existing clone, place yourself in and:

```bash
git fetch
git clean -fd
git checkout v0.14.1
```

Now you can install the new `fetchd` version:

```bash
make install

fetchd version
# must print v0.14.1
```

Make sure the version is correct before proceeding further!

### Docker image
Please use the `fetchai/fetchd:0.14.1` docker image, it is available on Docker Hub.

## Backup your node (**\*not\*** mandatory, but recommended)
Backup is not mandatory, though if something goes sideways, it will give you ability to revert back to the state when
the mainnet halted.

> Commands below **\*require\*** the `FETCHD_HOME_DIR` env variable to be set, see the
> [Set environment variables](#set-environment-variables)`.

:exclamation: Before doing this step, it is necessary to consider the amount of data nodes has in its home dir,
since backup might take considerable amount of time and disk space.
Run the following command to determine the amount of data of the node:
> ```shell
> du -sh $FETCHD_HOME_DIR
> ```

If decided to go ahead with the backup, below is the backup command
```shell
tar cf $FETCHD_HOME_DIR/node_backup.tar -C $FETCHD_HOME_DIR --exclude=wasm/wasm/cache config data wasm
```

## Execute upgrade procedure steps

### Confirm fetchd version
Confirm version of `fetchd` executable by executing following command:
```shell
fetchd version
```
> It **MUST** print `v0.14.1`. 

### Execute actual upgrade command
Simply start the **\*NEW\*** version (`v0.14.1`) of the `fetchd` node using the setup/configuration you usually use to start the node. 

**\*IF\*** your node home directory is default (`~/.fetchd`) run the following command: 
```shell
fetchd start
```
> , **\*OR\*** else provide the `--home $FETCHD_HOME_DIR` parameter (see the
> [Set environment variables](#set-environment-variables)`): 
> ```shell
> fetchd --home $FETCHD_HOME_DIR start
> ```

The line, like the one right below, must appear in the log, indicating that you are running the correct version of the
`fetchd` node executable.

```
11:36AM INF applying upgrade "v0.14.1" at height: 16915020
```


Once you see the lines like below being printed in the log, the upgrade procedure **has finished**:
```log
11:36AM INF minted coins from module account amount=486881463nanomobx from=mint module=x/bank
11:36AM INF minted coins from module account amount=4854128476nanonomx from=mint module=x/bank
11:36AM INF minted coins from module account amount=6374048957362866375atestfet from=mint module=x/bank
11:36AM INF executed block height=16915020 module=consensus num_invalid_txs=0 num_valid_txs=0
```

After this point, node is just waiting until enough validators have upgraded & joined the network (with at least 2/3
of the global stake), after which the mainnet consensus will resume block generation on its own, and the mainnet
upgrade procedure is finished from the conceptual standpoint.

### Verify upgrade completed

You can now query your **local** RPC endpoint to verify that the right version is running and the node properly
restarted:

```bash
curl -s http://localhost:26657/abci_info | jq -r '.result.response.version'
v0.14.1
```

> Make sure this print exactly the `v0.14.1` version. If not, double check you're on the right git tag in the `fetchd`
repository, that the `make install` didn't produce errors, and that your properly restarted your node.
