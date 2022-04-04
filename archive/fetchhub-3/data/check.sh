#!/bin/bash

set -euo pipefail


REG_FILE="./reconciliation_export.json"
SRC_GEN_FILE="./genesis_export_4504600.json"
FINAL_GEN_FILE="./genesis.json"
STAKE_EXPORT_FILE="./staked_export.csv"

for eth_addr in $(cat "${REG_FILE}" | jq -r '.[].eth_address'); do
    stake_migration_line=$(grep -i "${eth_addr}" "${STAKE_EXPORT_FILE}")
    
    old_native_addr=$(echo "${stake_migration_line}" | awk -F, '{print $3}')
    migrated_stake=$(echo "${stake_migration_line}" | awk -F, '{print $4}')
    
    new_native_addr=$(cat "${REG_FILE}" | jq -r --arg eth_addr "${eth_addr}" '.[]|select(.eth_address == $eth_addr).native_address')
    
    balance_before=$(cat "${SRC_GEN_FILE}" | jq -r --arg addr "${new_native_addr}" '.app_state.bank.balances[]|select(.address == $addr).coins[]|select(.denom == "afet").amount')
    if [ -z "${balance_before}" ]; then
        balance_before="0"
    fi
    
    balance_after=$(cat "${FINAL_GEN_FILE}" | jq -r --arg addr "${new_native_addr}" '.app_state.bank.balances[]|select(.address == $addr).coins[]|select(.denom == "afet").amount')
    if [ -z "${balance_after}" ]; then
        balance_after="0"
    fi
    
     balance_before_on_old=$(cat "${SRC_GEN_FILE}" | jq -r --arg addr "${old_native_addr}" '.app_state.bank.balances[]|select(.address == $addr).coins[]|select(.denom == "afet").amount')
    if [ -z "${balance_before_on_old}" ]; then
        balance_before_on_old="0"
    fi
    
    balance_after_on_old=$(cat "${FINAL_GEN_FILE}" | jq -r --arg addr "${old_native_addr}" '.app_state.bank.balances[]|select(.address == $addr).coins[]|select(.denom == "afet").amount')
    if [ -z "${balance_after_on_old}" ]; then
        balance_after_on_old="0"
    fi
    
    echo -n "${old_native_addr} -> ${new_native_addr}: "
    diff_old=$(echo "${balance_after_on_old}-${balance_before_on_old}" | bc)
    diff_new=$(echo "${balance_after}-${balance_before}" | bc)
    
    overall=$(echo "${diff_old}+${diff_new}" | bc)
    echo "${diff_old}, ${diff_new}, ${overall}"
done
