# ASI Genesis Migration

### Computer Resources:

Ensure that the computer carrying out this operation meets the following resource requirements for a smooth migration
process:

- **Memory**: 16GB RAM
- **CPU**: 4 cores on a local machine **or** 1 full core on the cloud
- **Disk Space**: 2GB free space

### In the event that these requirements are not met:

**NOTE**: these steps skip the computationally heavy portion of the upgrade

[//]: # (TODO: add reference to genesis.json download here)

- **RECOMMENDED**: backup the home directory in it's entirety, as
  explained [here](#3-not-mandatory-but-highly-recommended-backup-your-node).
- Download and replace the `genesis.json` file in the `~/.fetchd/config/`
  directory: ```curl GENESIS_URL > ~/.fetchd/config/genesis.json```
- [Proceed to Step 4.1](#41-verify-genesis-checksum).

> ### Important files
> It is **highly recommended** to backup these files before the upgrade, this process is
> detailed [here](#3-not-mandatory-but-highly-recommended-backup-your-node)
>- **FETCHD_HOME**: folder containing all of the validator data. By default, the `fetchd` command will automatically
   > create it under `~/.fetchd`, or in the location pointed by the `--home` flag on its first invocation; if it doesn't
   > exist.
>- FETCHD_HOME/config/**node_key.json**: this file hold your node private key.
>- FETCHD_HOME/config/**priv_validator_key.json**: this file hold your validator private key.
>- FETCHD_HOME/config/**config.toml**: this is your node configuration
>- FETCHD_HOME/config/**app.toml**: this configuration allows to tune the cosmos application, such as enabled apis,
   > telemetry, pruning.
>- FETCHD_HOME/config/**client.toml**: this file stores the client config. E.g. current node `chain-id`, `node`
   endpoint,
   > `keyring-backend`, etc.

---

### Verification Checksums

**NOTE**: During this upgrade, checksum verification is **highly recommended** at three critical instances:
- After exporting or downloading the un-upgraded `genesis.json` file.
- The `genesis.json` file **after** the upgrade process.
- The `asi_upgrade_manifest.json` file created by the upgrade process.

> Comparing these checksum values provides a reliable method to confirm whether the upgrade was executed correctly or not.

For each instance, use the following command to calculate the checksum:

```bash
sha256sum <path to file>
```

The output should somewhat resemble this:

```bash
fe5fe42dc375ae33268c88cb03fe0c030c96f08ad96ad21921c58fd02fe711c9  /home/.fetchd/config/genesis.json
```

The first set of characters is the SHA-256 checksum. This checksum should match the provided value to ensure the file
exactly matches the expected state. If the checksums do not match, the file may be corrupted, altered or otherwise
unsuitable.

Compare the generated checksum against the provided values at each checkpoint:

[//]: # (TODO: update with checksums)

| Checkpoint            | Filename                                     | SHA-256 Checksum Value |
|-----------------------|----------------------------------------------|------------------------|
| **Between steps 4-6** | `~/.fetchd/config/genesis.json`              | `123abc...`            |
| **After step 6**      | `~/.fetchd/config/genesis.json`              | `456def...`            |
| **After step 6**      | `~/.fetchd/config/asi_upgrade_manifest.json` | `789ghi...`            |

---

## 1. Obtain a Fully Synced Node:

Ensure you have a node that is completely synchronised with the mainnet network. This node must be capable of being
temporarily halted for the upgrade process. There are two ways to do so:

### 1.1 Existing Node:

When utilising an already existing node, such as an RPC or Sentry node, we begin by stopping the node at the upgrade
height.

This can be accomplished in two ways: either by halting the currently running `fetchd` process or by pre-setting the
`halt-height` parameter in the `~/.fetchd/config/app.toml` file to the desired height and restarting the node.
> NOTE: Ensure there is no active process manager, such as `systemd`, that will attempt to restart the node at this
> stage.

Once the node is halted at the specified height, it is synced and ready for the upgrade.

### 1.2 Newly Created Node:

This node should be dedicated solely to syncing with the network and should not serve any other function, such as RPC,
Sentry, or Validator.
To set up a new node for syncing with the network and preparing for the upgrade, follow these steps:

#### 1.2.1 Initialise the Home Directory and Node Parameters

```Bash
fetch --home ~/.fetchd init <moniker>
```

#### 1.2.2 Download the Genesis File

[//]: # (TODO: add reference to genesis.json download here)
Download the supplied `genesis.json` file and place it in the `~/.fetchd/config/` directory.

```Bash
curl ... > ~/.fetchd/config/genesis.json
```

#### 1.2.3 Set Network Parameters

Use `fetchd` as seen below or edit the `~/.fetchd/config/client.toml` file to set correct network parameters from
the [active-networks](https://fetch.ai/docs/references/ledger/active-networks) documentation

```Bash
fetchd --home ~/.fetchd config <parameter> <value>
```

#### 1.2.4 Optional: Set `Halt-Height` Parameter

This new node can be configured to halt itself at the desired height by setting the `halt-height` parameter in
the `~/.fetchd/config/app.toml` file.

#### 1.2.5 Run the Node

Ensure the node runs and syncs correctly:

```Bash
fetchd --home ~/.fetchd start --p2p.seeds=17693da418c15c95d629994a320e2c4f51a8069b@connect-fetchhub.fetch.ai:36456,a575c681c2861fe945f77cb3aba0357da294f1f2@connect-fetchhub.fetch.ai:36457,d7cda986c9f59ab9e05058a803c3d0300d15d8da@connect-fetchhub.fetch.ai:36458
```

> Ensure you supply the P2P seeds when first running this command,
> available [here](https://fetch.ai/docs/references/ledger/active-networks) under "Seed Nodes"

## 2. Wait for Official Scheduled Network Halt:

During the **official upgrade process**, the network will temporarily halt to perform a self-update.

- All connected nodes will pause at the same block height until they are upgraded.
- The latest halted state will be used to export the genesis state.
- After the restart, all nodes wishing to reconnect **must** match the new network parameters.

The expected output when this height is reached should look something like the following:

[//]: # (TODO: FILL THIS IS WITH UPDATED OUTPUT)

```
3:14PM ERR UPGRADE "v0.12.XX" NEEDED at height: 17000000: ASI Network Upgrade v0.12.XX (upgrade-info)
3:14PM ERR CONSENSUS FAILURE!!! err="UPGRADE \"v0.12.XX\" NEEDED at height: 17000000"
```

> Once this halt is reached, node operators **must** continue with these upgrade steps to restore consensus.

## 3. Not mandatory but HIGHLY recommended: Backup your node:

Strictly speaking this step is **NOT** mandatory, it is just for safety reasons if something goes wrong.

```shell
cp -rp ~/.fetchd ~/.fetchd_0.11.3_backup
```

## 4. Export `genesis.json` File:

Execute the following command to export the `genesis.json` file at the latest block height using the **current**
`fetchd v0.11.3` version:

> **NOTE**: This will **OVERRIDE** your original `genesis.json`.
> If you executed the [point above](#3-not-mandatory-but-highly-recommended-backup-your-node), you should have a backup.

> **REMINDER**: Ensure that the system where this command is executed has at least 16GB of memory.

> **REMINDER**: Ensure that the system has the required free space and expect the output file to be approximately
> 150-200MB.


The process will take roughly 5-10 minutes, depending on the system.

```bash
fetchd --home ~/.fetchd/ export > ~/.fetchd/config/genesis.json
```

## 5. Execute Complete Cleanup of fetchd Databases/Storage:

Perform a complete cleanup of fetchd databases and storage:
> NOTE: This command will **IRREVERSIBLY** clean/erase all data from node's storage databases.
> If you executed the [point above](#3-not-mandatory-but-highly-recommended-backup-your-node), you should have a backup.

## 6. Install NEW version `v0.12.LATEST` of `fetchd` node

There are two options, the correct choice depends on how you normally run your node:
> NOTE: The `LATEST` value in the version tag will be decided & published here when it will become known.

### 6.1 Build & install LOCAL version of new node

#### 6.1.1 Install Golang

We highly recommend to install `Go 1.18.10`, which is the latest version supported by go modules `fetchd` node
depends on.
Installation procedure depends on the OS you are using.
> All Golang releases are available [here](https://go.dev/dl/).

#### 6.1.2 EITHER Build & install LOCAL version of new node

[//]: # (TODO: Update with latest git tag)

```shell
git clone --depth --branch v0.12.LATEST https://github.com/fetchai/fetchd
cd fetchd
make install
```

[//]: # (TODO: Update with latest Docker image)

### 6.2 OR Use official docker image

This is for advanced users who are familiar with docker and related higher level infrastructure, like k8s, Helm Charts,
docker-compose, etc.
`fetchai/fetchd:0.12.LATEST`

## 7. Execute the ASI Upgrade Command:

Execute the ASI upgrade command to modify the genesis.json file in place:

> NOTE: The timestamp value below will be provided later when the exact upgrade time will become known.

[//]: # (TODO: UPDATE TIMESTAMP HERE WHEN AVAILABLE)

```bash
fetchd  --home ~/.fetchd/ asi-genesis-upgrade --genesis-time <Timestamp will be updated before upgrade>
```

This command will iterate through your newly-exported genesis file, updating each relevant network parameter to align
with the network consensus.

#### ASI Upgrade Manifest File

This file will be output to `~/.fetch/config/asi_upgrade_manifest.json` upon completing a run of the asi upgrade
command.

The upgrade manifest details all important parameter changes within the `genesis.json` file which the upgrade command
carried out.

> After executing the ASI upgrade command, it's important to verify the integrity of both the updated `genesis.json`
> file and the `asi_upgrade_manifest.json` output file by comparing checksums -
> see the [checksum verification](#verification-checksums) section. This ensures
> that the upgrade process was completed successfully.

## 8. Prepare and Start the Upgraded Node:

### 8.1 Update the node config

As mentioned [previously](#123-set-network-parameters), the `fetchd` network parameters must now be changed to
match those of the upgraded network.

Changing parameters can be achieved by using either the CLI or by manually editing the `~/.fetchd/config/client.toml`
file:

##### Using the CLI:

```Bash
fetchd --home ~/.fetchd config <parameter> <value>
```

[//]: # (TODO: supply new ASI config params)

| Parameter     | Value                   |
|---------------|-------------------------|
| chain-id      | `ASI-1`                 |
| node endpoint | `NEW ASI ENDPOINT HERE` |

### 8.2 Start the Node

[//]: # (TODO: UPDATE P2P SEEDS HERE)
> Ensure to supply the new upgraded P2P seeds provided ADD P2P SEEDS HERE

```bash
fetchd --home ~/.fetchd start --p2p.seeds=<ASI-P2P-SEEDS>
```
