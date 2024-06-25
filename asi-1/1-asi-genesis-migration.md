# ASI Genesis Migration

This is a "genesis" upgrade, what means that a new eon will be started, and all history from the previous eon will
be lost (it can be accessed from the archive node of the (previous) eon which will be ended by this upgrade).<br/>
Only the chain's full state (at the upgrade halt block height) will be carried over to the new eon.

## Prerequisites

### Computer Resources:

Ensure that the computer carrying out this operation meets the following resource requirements for a smooth migration
process:

- **Memory**: 16GB RAM
- **CPU**: 4 cores on a local machine **or** 1 full core on the cloud
- **Disk Space**: 2GB free space

### Assumptions
For the purposes of this upgrade guide, it is assumed that your node's **HOME** directory is the default `~/.fetchd`.
This is mostly relevant for **ALL** shell commands used in this guide, but this node home directory might also occur
in this guide in other contexts than just shell commands.

> **IF** this assumption is **NOT** correct for your particular node setup, please **REPLACE** all occurrences of the 
> `~/.fetchd` within this guide with a directory your node setup uses as its home directory.

## 1. Wait for network halt 

[//]: # (TODO: Replace HALT_BLOCK_HEIGHT and GOVERNANCE_PROPOSAL_NUMBER placeholders)

When mainnet blockchain reaches the target upgrade block height `HALT_BLOCK_HEIGHT` defined by the ASI software upgrade
governance proposal #GOVERNANCE_PROPOSAL_NUMBER, **ALL** nodes will automatically halt once they will reach this block
height.

It is **expected** to have an error logged by the node, similar to:

[//]: # (TODO: Replace v0.12.XX and HALT_BLOCK_HEIGHT placeholders)

```bash
3:14PM ERR UPGRADE "v0.12.XX" NEEDED at height: HALT_BLOCK_HEIGHT: ASI Network Upgrade v0.12.XX (upgrade-info)
3:14PM ERR CONSENSUS FAILURE!!! err="UPGRADE \"v0.12.XX\" NEEDED at height: HALT_BLOCK_HEIGHT"
```

## 2. Stop the node

Stop your node executable - this is essential to allow execution of further steps.<br/>
Procedure for stopping the node will differ depending on how you run your node.<br/>
:point_right: It is assumed as axiomatic that node operator knows how to stop the node.

## 3. Backup your node
Strictly speaking this step is not mandatory, however it is **HIGHLY** recommended to do.

### 3.1. \*EITHER\* Backup just ESSENTIAL files
```shell
tar czf ~/.fetchd_0.11.3_backup.tgz -C ~/.fetchd/config *_key.json *.toml
```

### 3.2. \*OR\* Full backup
```shell
tar cf ~/.fetchd_0.11.3_backup_full.tar -C ~/ --totals .fetchd
```

## 4. Choose the upgrade path
There are two (mutually exclusive) paths node operator can choose from to upgrade the node - **\*EITHER\*** the
[4.1](#41-either-simplified-path) **\*OR\***
[4.2](#42-or-execute-the-whole-upgrade-procedure-locally) section below.

### 4.1. [\*EITHER\*] Simplified path

This is the **simplest** method how to upgrade the node, since it bypasses execution of the whole upgrade procedure
locally, and rather simply waits until Fetch.ai executes the upgrade procedure, and then downloads the resulting
(upgraded) `genesis.json` file.

This path does **NOT** require to have fully synced node, in fact the node's home directory can be freshly
initialised.

> NOTE: At the end, all what is actually really necessary is to get the upgraded `genesis.json` file and upgrade the
> `fetchd` node binary.<br/>
> It does not matter who actually executes the full upgrade procedure (detailed in the 
> [4.2. [\*OR\*] Execute upgrade procedure](#42-or-execute-the-whole-upgrade-procedure-locally) section), and so 
> generates the resulting upgraded `genesis.json` file, since every execution of the full upgrade procedure
> **MUST ALWAYS** lead to the very same resulting `genesis.json` file.

### 4.1.1. Execute the [5. Reset of fetchd node storage](#5-reset-of-fetchd-node-storage) section and \*RETURN BACK\* here

### 4.1.2. Execute the [6. Install NEW version of the 'fetchd' node](#6-install-new-version-of-the-fetchd-node) section and \*RETURN BACK\* here

### 4.1.3. Download upgraded files
**\*Wait\*** until Fetch.ai finishes the upgrade procedure and publishes resulting upgraded files.<br/>
The publishing of the resulting files can be identified by monitoring the _"**AFTER** the upgrade"_ lines in table in the 
[SHA256 hashes of essential files at given checkpoints](#sha256-hashes-of-essential-files-at-given-checkpoints) section
for sha256 values (the `TO_BE_PROVIDED` placeholders value will be replaced by final sha256 values).

Once the resulting files have been published, execute following commands to download the files:

[//]: # (TODO: Verify that URLs below are active)

```shell
curl https://raw.githubusercontent.com/fetchai/genesis-fetchhub/feat/asi-upgrade-documentation/asi-1/assets/genesis-upgraded-v0.12.0.json.gz -o ~/.fetchd/config/genesis-upgraded-v0.12.0.json.gz
# The manifest file is NOT required for the upgrade, but it is suggested to be downloaded for bookkeeping purposes:
curl https://raw.githubusercontent.com/fetchai/genesis-fetchhub/feat/asi-upgrade-documentation/asi-1/assets/asi_upgrade_manifest-v0.12.0.json -o ~/.fetchd/config/asi_upgrade_manifest.json
```

### 4.1.4. Upgrade your node's `genesis.json`
```shell
gzip -d -c ~/.fetchd/config/genesis-upgraded-v0.12.0.json.gz > ~/.fetchd/config/genesis.json
```

### 4.1.5. Continue with execution from the [8. Verify sha256 hashes of resulting genesis and manifest files](#8-verify-sha256-hashes-of-resulting-genesis-and-manifest-files) section

---

### 4.2. [\*OR\*] Execute the whole upgrade procedure locally
This path describes how to execute upgrade procedure locally relying exclusively on your fully synced local node. 

#### 4.2.1 Export `genesis.json` file

Export procedure (the `export` CLI command) and overriding of the original `genesis.json` file must be executed in 2
separate commands, since the original `genesis.json` file must **\*not\*** modified while the export procedure is in
progress.

Use the **current** `fetchd v0.11.3` for executing the command below.<br/>
The process normally takes about 30 seconds, but it might take up to 10 minutes depending on your hardware (CPU
and disk speed).
```bash
fetchd --home ~/.fetchd export > ~/.fetchd/config/genesis.exported.json
```
Overriding original genesis with exported one:
```bash
cp -p ~/.fetchd/config/genesis.exported.json ~/.fetchd/config/genesis.json
```

#### 4.2.2. Verify sha256 hashes of `genesis.exported.json` and `genesis.json` files
Run the following command to generate sha256 hashes for both files:
```bash
❯ shasum -a 256 ~/.fetchd/config/genesis.exported.json ~/.fetchd/config/genesis.json
```

**VERIFY** the resulting hashes against the **\*REFERENCE\*** hash values provided in the
[SHA256 hashes of essential files at given checkpoints](#sha256-hashes-of-essential-files-at-given-checkpoints) section
for this checkpoint.

## 5. Reset of fetchd node storage

**IMPORTANT**: This command will **IRREVERSIBLY** erase all data from node's storage databases.
```bash
fetchd --home ~/.fetchd/ tendermint unsafe-reset-all
```

## 6. Install `v0.12.LATEST` version of the `fetchd` node

> NOTE: The `LATEST` placeholder used below in this section will be replaced with final git tag value when it becomes known.

There are two options - either do **local** installation, or using the **docker** (see the related sections below).
The right choice depends only on how you normally run your node.

### 6.1. \*EITHER\* Build & install LOCAL version of new node
> #### PREREQUISITE: Install Golang
> We highly recommend to use the `go1.18.10`, which is the latest version supported by go modules `fetchd` node
> depends on.
> Installation procedure depends on the OS you are using.
> All Golang releases are available [here](https://go.dev/dl/).

It is recommended to go with fresh clone of fetchd git repository rather than use the already existing one:

[//]: # (TODO: Replace the LATEST placeholder with correct git tag)
```shell
git clone --depth --branch v0.12.LATEST https://github.com/fetchai/fetchd
cd fetchd
make install
```

[//]: # (TODO: Update with latest git tag)

> **ALTERNATIVELY**: **IF** it is required/desired to use **already existing** clone of fetchd repository:
> ```bash
> cd fetch
> git fetch
> git clean -fd
> git reset .
> git checkout v0.12.LATEST
> make install
> ```

### 6.1.1. \*VERIFY\* version of the newly installed `fetchd` node

```bash
fetchd version
```

[//]: # (TODO: Replace the LATEST placeholder with correct git tag)

:point_right: The above command **\*MUST\*** print the `v0.12.LATEST`! If it doesn't, please analyse the commands
executed above in the scope of the 
[6.1. \*EITHER\* Build & install LOCAL version of new node](#61-either-build--install-local-version-of-new-node)
section (when you reach this point we suggest to go with fresh clone of the git repo).

[//]: # (TODO: Update with latest Docker image)

### 6.2. \*OR\* Use official docker image `fetchai/fetchd:0.12.LATEST`

This is for advanced users, who are familiar with docker and related higher level infrastructure, like k8s, Helm Charts,
docker-compose, etc.

## 7. Execute the ASI Upgrade

The following command will execute the actual ASI upgrade. As the result it will modify
`~/.fetchd/config/genesis.json` file **IN PLACE**:

> NOTE: The timestamp value below will be provided later when the exact upgrade time will become known.

[//]: # (TODO: Replace the ASI_GENESIS_UPGRADE_TIMESTAMP with real value)

```bash
fetchd  --home ~/.fetchd/ asi-genesis-upgrade --genesis-time ASI_GENESIS_UPGRADE_TIMESTAMP
```

### 7.1 ASI Upgrade Manifest File
> As a side effect, the `asi-genesis-upgrade` CLI command above also creates the 
> `~/.fetch/config/asi_upgrade_manifest.json` file.<br>
> This manifest file will reflect all changes made to the `genesis.json` file during the ASI upgrade procedure.

## 8. Verify sha256 hashes of resulting genesis and manifest files
Run the following command to generate sha256 hashes for both files: 
```bash
❯ shasum -a 256 ~/.fetchd_asi_mainnet_upgrade_test/config/genesis.json ~/.fetchd_asi_mainnet_upgrade_test/config/asi_upgrade_manifest.json
```

**VERIFY** the resulting hashes against the **\*REFERENCE\*** hash values provided in the
[SHA256 hashes of essential files at given checkpoints](#sha256-hashes-of-essential-files-at-given-checkpoints) section for given phase. 
If hash values do not match something is wrong, and you need to start the upgrade process again starting from the
[4.2.1 Export 'genesis.json' file](#421-export-genesisjson-file) section.

## 9. Start the new node

> **IMPORTANT**: Ensure to provide the **NEW** p2p seeds as they are provided in the command below.<br>

[//]: # (TODO: Replace the ASI_P2P_SEEDS value)

```bash
fetchd --home ~/.fetchd start --p2p.seeds=ASI_P2P_SEEDS
```

## 10. Update the node config (not mandatory, but recommended)
The following parameters should be updated in the `~/.fetchd/config/client.toml` file using new values provided in the
table below:

[//]: # (TODO: Replace ASI_RPC_ENDPOINT placeholder)

| Requirement Level                            | Parameter  | Value              | Description                                                                                                                                                                                                 |
|----------------------------------------------|------------|--------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| RECOMMENDED                                  | `chain-id` | `asi-1`            | > The network chain ID                                                                                                                                                                                      |
| OPTIONAL<br>_(see the "Description" column)_ | `node`     | `ASI_RPC_ENDPOINT` | > URL of Tendermint RPC interface<br/>:point_right: Change this **ONLY** if you really need to = only if your current RPC url in the `client.toml` file explicitly points to external **old** mainnet node. |

<!---
(NOTE\(pb\): It does **NOT** make sense to suggest here to change value of the `node` parameter
\(the `ASI_RPC_ENDPOINT`- see the commented out table line below\), since this whole upgrade quide is for node
operators = they run their own node they are upgrading right now = they can use its **LOCAL** node RPC endpoint url,
which is by default `tcp://127.0.0.1:26657` \(and most probably already have that configured\), to run all
`fetchd` CLI commands.
----------
==> Additional argument against suggesting to change this value is \(and it is perhaps even stronger than the previous
one above\), that node operators should **NOT** need to run such `fetchd` CLI commands which need to send requests
to RPC endpoint from **INSIDE** of the node production environment \(e.g. from inside the docker container where
the node runs\) - for example CLI command for queries or signing/broadcasting TXs.
All such `fetchd` CLI commands shall be executed from **OUTSIDE** of the node poduction runtime environment -
e.g. from a local computer, or from other docker container, which will have its **OWN & SEPARATE** `~/.fetchd` home
directory and with is also its own `client.toml`.) 
--->

Changing parameters can be achieved either manually by editing the `~/.fetchd/config/client.toml` config file, or
alternatively by using the `fetchd` CLI (see below).

> Alternatively, use the CLI (instead of direct editing of the `client.toml` file):
>
> ```Bash
> fetchd --home ~/.fetchd config <parameter> <value>
> ```

---

## SHA256 hashes of essential files at given checkpoints
The table below contains the **\*REFERENCE\*** hash values for essential files at important checkpoints.

> If hash values generated from the files at given checkpoints do not match the reference hash values provided in the
> table below, something is **\*wrong\***, and it is necessary to restart the upgrade process again from the
> [4.2.1. Export 'genesis.json' File](#421-export-genesisjson-file) section (including), in which case it is close to
> certainty it will be either necessary to use the full backup (if it was made), or (**IF** the full backup was **NOT**
> made) to recover via [4.1. Simplified path](#41-either-simplified-path).

> Note: The reference hash values currently provided in the table below are just placeholders, and will be updated
> with real/correct values when they will become known.

[//]: # (TODO: update with checksums)

| Checkpoint                                                                                                                                                                                                                                  | Filename                                            | Reference sha256 hash value |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------|-----------------------------|
| **BEFORE** the upgrade<br/>**[Step 4.2.2.](#422-verify-sha256-hashes-of-genesisexportedjson-and-genesisjson-files)**                                                                                                                        | `~/.fetchd/config/genesis.exported.json`            | `TO_BE_PROVIDED`            |
| **BEFORE** the upgrade<br/>**[Step 4.2.2.](#422-verify-sha256-hashes-of-genesisexportedjson-and-genesisjson-files)**                                                                                                                        | `~/.fetchd/config/genesis.json`                     | `TO_BE_PROVIDED`            |
| **AFTER** the upgrade<br/>**[Step 4.1.5.](#415-continue-with-execution-from-the-8-verify-sha256-hashes-of-resulting-genesis-and-manifest-files-section)**                                                                                   | `~/.fetchd/config/genesis-upgraded-v0.12.0.json.gz` | `TO_BE_PROVIDED`            |
| **AFTER** the upgrade<br/>**[Step 4.1.5.](#415-continue-with-execution-from-the-8-verify-sha256-hashes-of-resulting-genesis-and-manifest-files-section)** or **[step 8.](#8-verify-sha256-hashes-of-resulting-genesis-and-manifest-files)** | `~/.fetchd/config/genesis.json`                     | `TO_BE_PROVIDED`            |
| **AFTER** the upgrade<br/>**[Step 4.1.5.](#415-continue-with-execution-from-the-8-verify-sha256-hashes-of-resulting-genesis-and-manifest-files-section)** or **[step 8.](#8-verify-sha256-hashes-of-resulting-genesis-and-manifest-files)** | `~/.fetchd/config/asi_upgrade_manifest.json`        | `TO_BE_PROVIDED`            |
