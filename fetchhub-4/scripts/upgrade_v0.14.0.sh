#!/usr/bin/env bash
set -e

#DEFAULT_FETCHD_HOME_DIR=~/.fetchd

# Check if a parameter is passed
if [ -n "$1" ]; then
  FETCHD_HOME_DIR="$1"
else
  #FETCHD_HOME_DIR="$DEFAULT_FETCHD_HOME_DIR"
  SCRIPT_NAME=$(basename "$0")
  echo "Usage: $SCRIPT_NAME <fetchd_home_dir>"
  echo "  fetchd_home_dir - homed directory of the fetchd node,"
  echo "                    must be explicitly provided to avoid implicit"
  echo "                    quiet defaulting to the ~/.fetchd dir, when it"
  echo "                    might not be desired."
  echo "                    !! If you need to use quotes \"...\" in the value,"
  echo "                    and at the same time the ~ (tilde expansion"
  echo "                    variable), do *not* include the ~ tilde expansion"
  echo "                    character in between the quotes."
  echo "Example: $SCRIPT_NAME ~/.fetchd"
  exit
fi

#Setting primary env variables:
export FETCHD_HOME_DIR
export DESTINATION_CHAIN_ID="fetchhub-4"
export GENESIS_FETCHHUB_GIT_REVISION="tags/v0.14.0"

export UPGRADE_SHA256_PARAMS="--cudos-genesis-sha256 5eec16016006524b40f7777dece37ad07e3a514c20718e9cf0dca3082693e74b --cudos-migration-config-sha256 e1631e27629f9e32a5ec6c8fdd56d0d8ec31d7cd6b6a5e2662ce107b56f623ee"

# Downloading necessary files for the upgrade:
curl https://raw.githubusercontent.com/fetchai/genesis-fetchhub/refs/$GENESIS_FETCHHUB_GIT_REVISION/fetchhub-4/data/cudos_merge_config.json -o "$FETCHD_HOME_DIR/cudos_merge_config.json"
curl https://raw.githubusercontent.com/fetchai/genesis-fetchhub/refs/$GENESIS_FETCHHUB_GIT_REVISION/fetchhub-4/data/genesis.cudos.json.gz -o "$FETCHD_HOME_DIR/genesis.cudos.json.gz"

# Decompressing the CUDOS genesis file:
gzip -d -c "$FETCHD_HOME_DIR/genesis.cudos.json.gz" > "$FETCHD_HOME_DIR/genesis.cudos.json"

# Executing the upgrade:
echo PLEASE EXECUTE THE FOLLOWING COMMANDLINE TO UPGRADE THE NODE:
UPGRADE_CMD="fetchd --home \"$FETCHD_HOME_DIR\" start --cudos-genesis-path \"$FETCHD_HOME_DIR/genesis.cudos.json\" --cudos-migration-config-path \"$FETCHD_HOME_DIR/cudos_merge_config.json\" $UPGRADE_SHA256_PARAMS"
echo $UPGRADE_CMD
