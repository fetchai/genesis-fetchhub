# Eridanus Genesis Migration

### Computer Resources:

Ensure that the computer carrying out this operation meets the following resource requirements for a smooth migration
process:

- **Memory**: 32GB RAM
- **CPU**: 1 core on the cloud **or** 4 cores on a local machine
- **Disk Space**: 4GB free space

[//]: # (TODO: INSERT REFERENCE TO GENESIS.JSON FILE)

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

## 4. Export `genesis.json` File:

Execute the following command to export the `genesis.json` file at the latest block height:

```bash
fetchd export > genesis.json
```

- after the chevron symbol `>`, specify the path and/or filename where the `genesis.json` file should be saved.
    - The example provided will output the a file called `genesis.json` to the current CLI directory.
- **REMINDER**: Ensure that the system where this command is executed has at least 32GB of memory.
- **REMINDER**: Ensure that the system has the required free space and expect the output file to be approximately 3GB.
- The process may take around 10 minutes, depending on the system.

[//]: # (TODO: INSERT REFERENCE TO PRUNING SCRIPT)

## 5. Prune Contract Bytecodes:

Execute the pruning script provided **INSERT PRUNING SCRIPT PATH HERE** to remove redundant contract bytecodes from the
genesis.json file:

```bash
cd ./scripts
poetry install
poetry shell
python3 prune_genesis_codes.py latest-dorado-genesis-exported.json --output_file genesis_pruned.json
```

- This will reduce the size of the `genesis.json` by removing redundant and/or repeated contract bytecodes.
- The pruned output `genesis_pruned.json` file will be roughly 850MB.

[//]: # (TODO: clarify managing which genesis.json goes where etc.)

## 6. Execute the ASI Upgrade Command:
Execute the ASI upgrade command to modify the genesis.json file in place:
 
```bash
fetchd asi-genesis-upgrade
```

## 7. Execute Complete Cleanup of fetchd Databases/Storage:
Perform a complete cleanup of fetchd databases and storage:

```bash
fetchd tendermint unsafe-reset-all
```