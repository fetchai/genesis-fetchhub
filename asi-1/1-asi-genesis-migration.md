# ASI Genesis Migration

### Computer Resources:

Ensure that the computer carrying out this operation meets the following resource requirements for a smooth migration
process:

- **Memory**: 16GB RAM
- **CPU**: 1 core on the cloud **or** 4 cores on a local machine
- **Disk Space**: 2GB free space

#### *In the event that these requirements are not met*

- download the `genesis.json` file provided  **INSERT PATH HERE**
- replace the current `genesis.json` file in the `~/.fetchd/config/` directory with the downloaded file
- [proceed to Step 6](#6-execute-the-asi-upgrade-command)

## 2. Obtain a Fully Synced Node:

Get a node that is fully synced with the blockchain network. This node should be able to be stopped temporarily for the
upgrade procedure. There are two options for obtaining such a node:

- **Existing Node**: Utilize an already existing node, such as an RPC or Sentry node.
- **Newly Created Node**: Set up a new node specifically for this purpose. This node should be dedicated solely to
  syncing with the network and should not serve any other function, such as RPC, Sentry, or Validator.

## 3. Stop the Node at Desired Time:

Stop the node at the desired time to capture the state at a specific block height. The last block height at the time of
stopping the node will be used to export the genesis state.

## 4. Not mandatory but HIGHLY recommended: Backup your node:
Strictly speaking this step is **NOT** mandatory, it is just for safety reasons if somthing goes wrong.
```shell
cp -rp ~/.fetchd ~/.fetchd_0.11.3_backup
```

## 5. Export `genesis.json` File:

Execute the following command to export the `genesis.json` file at the latest block height using the **current** 
`fetchd v0.11.3` version:

```bash
fetchd export > genesis.json
```

- after the chevron symbol `>`, specify the path and/or filename where the `genesis.json` file should be saved.
    - The example provided will override/create the `genesis.json` file to the **default** node directory (which is
      the `~/.fetchd/config`).
- **REMINDER**: Ensure that the system where this command is executed has at least 32GB of memory.
- **REMINDER**: Ensure that the system has the required free space and expect the output file to be approximately 3GB.
- The process may take around 10 minutes, depending on the system.

## 6. Install NEW version `v0.12.LATEST` of `fetchd` node
You have 2 options, the picks ill depend on how you normally run your node: 
> NOTE: The `LATEST` value in the version tag will be decided & publicised here when it will become known.
### 6.1. Build & install LOCAL version of new node
#### 6.1.1. Install go lang
We highly recommend to install `go1.18.10`, which is the latest version supported by go modules `fetchd` node
depends on.
Installation procedure depends on the OS you are using.

#### 6.1.2. EITHER Build & install LOCAL version of new node
```shell
git clone --depth --branch v0.12.LATEST https://github.com/fetchai/fetchd
cd fetchd
make install
```

### 6.2. OR Use official docker image `fetchai/fetchd:0.12.LATEST`
This is for advanced users who are familiar with docker and related higher level infrastructure, like k8s, Helm Charts,
docker-compose, etc. ...

## 7. **EXCLUSIVELY for TESTNET** (\*NOT\* for mainnet) Prune Contract Bytecodes:
Execute the pruning script provided **INSERT PRUNING SCRIPT PATH HERE** to remove redundant contract bytecodes from the
genesis.json file:

> **Do NOT execute this for mainnet!**

```bash
cd ./scripts
poetry install
poetry shell
python3 prune_genesis_codes.py latest-dorado-genesis-exported.json --output_file genesis_pruned.json
```

- This will reduce the size of the `genesis.json` by removing redundant and/or repeated contract bytecodes.
- The pruned output `genesis_pruned.json` file will be roughly 850MB.

The `genesis_pruned.json` file is the resulting genesis file and ultimately should be copied to location expected by
node: 
> NOTE: This will **OVERRIDE** your original `genesis.json`.
> If you executed the point 4. above, you should have a backup.
```shell
mv ~/.fetchd/config/genesis_pruned.json ~/.fetchd/config/genesis.json
```

## 8. Execute the ASI Upgrade Command:
Execute the ASI upgrade command to modify the genesis.json file in place:

> NOTE: The timestamp value below will be provided later when the exact upgrade time will become known.
```bash
fetchd asi-genesis-upgrade --genesis-time TIMESTAMP_WILL_BE_SPECIFIED_LATER
```

## 9. Execute Complete Cleanup of fetchd Databases/Storage:
Perform a complete cleanup of fetchd databases and storage:
> NOTE: This command will IRREVERSIBLY clean/erase all data from node's storage databases.
> If you executed the point 4. above, you should have a backup.
```bash
fetchd tendermint unsafe-reset-all
```
## 9. Start the upgraded node:
```bash
fetchd start
```
