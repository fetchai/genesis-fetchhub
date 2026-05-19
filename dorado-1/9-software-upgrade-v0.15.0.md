# Software upgrade

This guide describes the procedure to upgrade to `fetchd v0.15.0` following the corresponding software upgrade governance proposal.

We kindly ask all validators and node operators to read through the following document carefully, and then wait until the chain reaches the upgrade block height defined in the governance proposal *before* executing the upgrade steps.

In case of questions or issues, feel free to reach me on Discord (`@v0id.ptr`), or Telegram [@v0idptr](https://t.me/v0idptr).

# About the upgrade

The `v0.15.0` release is a major network upgrade. It brings the Fetch.ai chain to a substantially newer blockchain stack and introduces several new protocol modules.

The main platform upgrade is:

* Upgrade to `fetchai/cosmos-sdk v0.20.0`, based on canonical `cosmos-sdk v0.53.7`.

This upgrade updates all major components of the blockchain stack:

| Component | Previous version | New version |
|---|---:|---:|
| `cosmos-sdk` | `fetchai v0.19.4` / canonical `v0.45.9` | `fetchai v0.20.0` / canonical `v0.53.7` |
| Consensus engine | `tendermint v0.34.21` | `cometbft v0.38.21` |
| `wasmd` | `v0.27.0` | `v0.61.11` |
| `wasmvm` | `v1.0.1` | `v3.0.4` |
| `ibc-go` | `v3.1.1-fetchai` | `v10.6.0` |

This is a significant upgrade, including a change of the consensus engine from Tendermint to CometBFT.

In addition, the upgrade introduces the following new modules:

* **Liquid Staking Module**, based on the Gaia `v27.3.0` implementation.
* **TokenFactory Module**, `fetchai/tokenfactory v0.1.0`, forked from `strangelove-ventures/tokenfactory v0.50.3`.
* Multiple newer Cosmos SDK modules, most notably the **group** module.

Because of the scope of the dependency changes and state migrations involved, this should be treated as a **breaking and resource-intensive upgrade**. Operators must ensure that their nodes have sufficient CPU and memory available during the migration, and that the new required node configuration is present before startup.

# Pre-requisites

## Set environment variables

We suggest setting the following environment variable, since it is used in commands below:

> :warning: If you need to use quotes `"..."` in a value of the environment variable below **\*and\*** at the same time the `~` tilde expansion variable, please do **\*not\*** include the tilde expansion character inside quotes.

```shell
export FETCHD_HOME_DIR=~/.fetchd
```

## Ensure sufficient machine resources

The `v0.15.0` upgrade performs a large in-place state migration and has materially higher temporary resource requirements than routine patch upgrades.

Observed upgrade resource requirements are:

| Node profile | Approximate storage | Peak memory during upgrade | Approximate upgrade duration |
|---|---:|---:|---:|
| Validator-like node | ~500 GB | ~13 GB | ~50 minutes |
| Archive node | ~1.5 TB | ~21 GB | ~1 hour 20 minutes |

All nodes may temporarily use up to approximately **2 CPU cores** during the upgrade.

### Recommended Kubernetes / VM sizing

For upgrade execution, we strongly recommend provisioning at least:

| Node type | Recommended memory request | CPU |
|---|---:|---:|
| Archive nodes | **32 GB RAM** | **2 CPU cores** |
| Validators, RPC, internal, sentry, and similar nodes | **22 GB RAM** | **2 CPU cores** |

For Kubernetes deployments:

* Prefer setting an appropriate **memory request**.
* We recommend **removing the memory limits section** for the upgrade procedure. If a node is terminated by Kubernetes due to an out-of-memory condition during migration, the upgrade process may be interrupted in an unsafe state and may require additional recovery steps.

> :exclamation: Please make sure that the infrastructure sizing is adjusted **before** restarting nodes with `fetchd v0.15.0`.

## Configure minimum gas prices

Starting with `fetchd v0.15.0`, the node must have `minimum-gas-prices` configured.

If this setting is missing, the node will fail to start with an error similar to:

```log
Error: set min gas price in app.toml or flag or env variable: error in app.toml
```

### Recommended configuration

We recommend setting this permanently in:

```shell
$FETCHD_HOME_DIR/config/app.toml
```

For example:

```toml
minimum-gas-prices = "0afet"
```

Alternatively, the node can be started by providing the flag explicitly:

```shell
fetchd start --minimum-gas-prices 0afet
```

or, when using a non-default home directory:

```shell
fetchd --home $FETCHD_HOME_DIR start --minimum-gas-prices 0afet
```

# Upgrade procedure

## Chain halt

Wait until the blockchain reaches the target upgrade block height `23387874` defined in the governance proposal [[#43] Upgrade to fetchai CosmosSDK v0.20.0 (canonical v0.53.7)](https://hub.fetch.ai/dorado-1/proposals/47).
At that point, all nodes will halt.
It is **\*expected\*** to see an upgrade-required error in the logs similar to:

```log
ERR UPGRADE "v0.15.0" NEEDED at height: `23387874`
ERR CONSENSUS FAILURE!!! err="UPGRADE \"v0.15.0\" NEEDED at height: `23387874`"
```

Once this happens, node operators can proceed with installation of the new `v0.15.0` version of the `fetchd` executable.

## Install new fetchd version

You can either build the `fetchd` executable locally, or use the Docker image prepared for this release.

### Local build

You may already have the `fetchd` repository on your machine from the previous installation. If not, you can clone it as follows:

```bash
git clone --branch v0.15.0 https://github.com/fetchai/fetchd fetchd_v0.15.0
cd fetchd_v0.15.0
```

If you already have an existing clone, place yourself in the repository and run:

```bash
git fetch
git clean -fd
git checkout v0.15.0
```

Now install the new `fetchd` version:

```bash
make install

fetchd version
# must print v0.15.0
```

Make sure the version is correct before proceeding further.

### Docker image

Please use the Docker image corresponding to the `v0.15.0` release, if one is provided for your deployment workflow.

## Backup your node (**\*not\*** mandatory, but recommended)

A backup is not mandatory, though if something goes sideways, it gives operators the ability to revert to the state at which the mainnet halted.

> Commands below **\*require\*** the `FETCHD_HOME_DIR` environment variable to be set. See [Set environment variables](#set-environment-variables).

:exclamation: Before doing this step, consider the amount of data in the node home directory, since backup may take a considerable amount of time and disk space.

Run the following command to determine the amount of data stored by the node:

```shell
du -sh $FETCHD_HOME_DIR
```

If you decide to proceed with a backup, use:

```shell
tar cf $FETCHD_HOME_DIR/node_backup.tar -C $FETCHD_HOME_DIR --exclude=wasm/wasm/cache config data wasm
```

# Execute upgrade procedure steps

## Confirm fetchd version

Confirm the version of the `fetchd` executable:

```shell
fetchd version
```

> It **MUST** print `v0.15.0`.

## Confirm minimum gas prices configuration

Before starting the upgraded node, make sure one of the following is true:

1. `minimum-gas-prices = "0afet"` is configured in `$FETCHD_HOME_DIR/config/app.toml`, or
2. the node startup command includes `--minimum-gas-prices 0afet`.

If neither is configured, the node will fail to start.

## Execute the actual upgrade

Start the **\*NEW\*** version (`v0.15.0`) of the `fetchd` node using the setup/configuration you usually use to start the node.

If your node home directory is default (`~/.fetchd`) and `minimum-gas-prices` has been configured in `app.toml`, run:

```shell
fetchd start
```

If your node home directory is default and you prefer to pass the minimum gas prices as a startup flag, run:

```shell
fetchd start --minimum-gas-prices 0afet
```

If your node uses a custom home directory, run for example:

```shell
fetchd --home $FETCHD_HOME_DIR start
```

or:

```shell
fetchd --home $FETCHD_HOME_DIR start --minimum-gas-prices 0afet
```

# Expected upgrade logs

After startup, the node will begin the migration process. The exact upgrade name and block height shown in the logs will correspond to the governance proposal, but the upgrade output is expected to include the following kinds of entries:

```log
INF starting node with ABCI CometBFT in-process module=server
INF ABCI Handshake App Info ... software-version=v0.15.0
INF applying upgrade "v0.15.0..." at height: `23387874` module=x/upgrade
```

During the migration, it is expected to see many module migrations and new module registrations, including entries such as:

```log
INF adding a new module: consensus module=baseapp
INF adding a new module: group module=baseapp
INF adding a new module: liquid module=baseapp
INF adding a new module: tokenfactory module=baseapp
INF migrating module gov ...
INF migrating module ibc ...
INF migrating module staking ...
INF migrating module wasm ...
```

The test upgrade logs also showed transient consensus-parameter lookup messages early during replay:

```log
ERR failed to get consensus params err="collections: not found: key 'no_key' of type github.com/cosmos/gogoproto/tendermint.types.ConsensusParams" module=baseapp
```

In the observed upgrade run, these messages appeared before the actual migration proceeded and completed successfully. Operators should primarily verify that the node continues into the upgrade migration and reaches the successful block finalization stage.

Once the upgrade migration finishes, logs similar to the following should appear:

```log
INF finalized block ... height=`23387874` module=consensus ...
INF executed block ... height=`23387874` module=consensus
INF committed state ... height=`23387874` module=consensus
INF Completed ABCI Handshake - CometBFT and App are synced ...
INF Version info ... tendermint_version=0.38.x
```

After this point, the node waits until enough validators have upgraded and rejoined the network, with at least 2/3 of the global stake online. Once that threshold is reached, mainnet consensus resumes block generation automatically, and the network upgrade procedure is finished from the conceptual standpoint.

# Verify upgrade completed

You can query your **local** RPC endpoint to verify that the expected application version is running and that the node restarted correctly:

```bash
curl -s http://localhost:26657/abci_info | jq -r '.result.response.version'
v0.15.0
```

> Make sure this prints exactly `v0.15.0`. If not, double-check that:
>
> * you are on the correct Git tag in the `fetchd` repository,
> * `make install` completed successfully,
> * the correct binary or container image is being started,
> * and the node was properly restarted after the chain halt.
