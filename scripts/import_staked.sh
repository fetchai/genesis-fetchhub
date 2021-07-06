#!/bin/bash

set -uoe pipefail

usage() {
    echo "Add delegations in the genesis file from a CSV file."
    echo "The genesis from FETCHD_HOME (default: ~/.fetchd/) will be updated."
    echo -e "\nUsage:\n    $0 [csv_file]\n" 
    echo -e "Env:"
    echo -e "    FETCHD_HOME: specify the location of the fetchd home folder\n"
    exit 1
}

FETCHD_HOME="${FETCHD_HOME:=~/.fetchd/}"
# Validators that will receive delegations, in a round-robin fashion
TARGET_VALIDATORS=(
    "fetchvaloper1xrlqqepyfl64mjr8x837y5slxfzlywe57rwdta" # novus1
    "fetchvaloper1w8659233jlf42n68xsqw9w3ssjquyr8jha64hy" # novus2
    "fetchvaloper14w6a4al72uc3fpfy4lqtg0a7xtkx3w7hda0vel" # uvue1
    "fetchvaloper1ufarthku3aw4rjeexdwk9r2wj20evdnw86ceee" # uvue2
)
BOND_DENOM="afet"
# minimum amount required to create a delegation, below, no delegation is 
# created and everything is transferred on the user account
MIN_DELEGATED_AMOUNT="2000000000000000000${BOND_DENOM}"
# amount subtracted from the delegated amount and transferred 
# on the user account when a delegation is created 
ACCOUNT_RESERVED_AMOUNT="1000000000000000000${BOND_DENOM}"
# Number of expected fields per line in the CSV file
EXPECTED_NUMFIELDS="6"

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

CSV_FILE="$1"

if [ ! -f "${CSV_FILE}" ]; then
    usage
    exit 1
fi

NUMFIELDS=$(head -n1 "${CSV_FILE}" | awk -F',' '{print NF}')
if [ "${NUMFIELDS}" -ne "${EXPECTED_NUMFIELDS}" ]; then 
    echo "invalid CSV file, expected ${EXPECTED_NUMFIELDS}, got ${NUMFIELDS}"
    exit 1
fi

FETCHD_HOME=$(realpath "${FETCHD_HOME}")
GENESIS_FILE="${FETCHD_HOME}/config/genesis.json"
if [ ! -f "${GENESIS_FILE}" ]; then
    echo "Cannot read genesis.json from ${FETCHD_HOME}"
    exit 1
fi

ORIGINAL_GENESIS="${GENESIS_FILE}.orig"
# Backup current genesis. In case of errors while adding delegations,
# genesis file will be reverted to pristine state.
cp -f "${GENESIS_FILE}" "${ORIGINAL_GENESIS}"

restore () {
    echo "An error occured, reverting the genesis.json to previous state"
    cp -f "${ORIGINAL_GENESIS}" "${GENESIS_FILE}"
}
cleanup () {
    rm "${ORIGINAL_GENESIS}"
}

trap restore ERR
trap cleanup EXIT

COUNTER=0
while read -r line; do
    FETCH_ADDR=$(echo "${line}" | awk -F',' '{print $3}')
    VALIDATOR=${TARGET_VALIDATORS[$((COUNTER % ${#TARGET_VALIDATORS[@]}))]}
    AMOUNT=$(echo "${line}" | awk -F',' '{print $4}')
    fetchd add-genesis-delegation \
        --home "${FETCHD_HOME}" \
        --account-reserved-amount ${ACCOUNT_RESERVED_AMOUNT} \
        --min-delegated-amount ${MIN_DELEGATED_AMOUNT} \
        "${FETCH_ADDR}" "${VALIDATOR}" "${AMOUNT}${BOND_DENOM}" 
    echo "Added delegation from ${FETCH_ADDR} to ${VALIDATOR} of ${AMOUNT}${BOND_DENOM}"
    COUNTER=$((COUNTER + 1))
done <<<"$(sort "${CSV_FILE}")"
