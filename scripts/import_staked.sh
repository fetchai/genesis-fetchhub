#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Number of expected fields per line in the CSV file
EXPECTED_NUMFIELDS="6"
TARGET_VALIDATORS=(
    "fetchvaloper1xrlqqepyfl64mjr8x837y5slxfzlywe57rwdta" # novus1
    "fetchvaloper1w8659233jlf42n68xsqw9w3ssjquyr8jha64hy" # novus2
    "fetchvaloper14w6a4al72uc3fpfy4lqtg0a7xtkx3w7hda0vel" # uvue1
    "fetchvaloper1ufarthku3aw4rjeexdwk9r2wj20evdnw86ceee" # uvue2
)
BOND_DENOM="afet"

# Minimum amount required to create a delegation. If account have less, it's just skipped.
MIN_AMOUNT=2000000000000000000

set -uo pipefail

usage() {
    echo "Add delegations in genesis file from a CSV file"
    echo -e "\nUsage: $0 [csv_file]\n" 
    exit 1
}

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

COUNTER=0
while read line; do
    FETCH_ADDR=$(echo "${line}" | awk -F',' '{print $3}')
    VALIDATOR=${TARGET_VALIDATORS[$((${COUNTER} % ${#TARGET_VALIDATORS[@]}))]}
    AMOUNT=$(echo "${line}" | awk -F',' '{print $4}')
    if [[ $(bc <<< "${AMOUNT} >= ${MIN_AMOUNT}" ) -eq 1 ]]; then
        COUNTER=$(($COUNTER + 1))
        fetchd add-genesis-delegation --bond-denom "${BOND_DENOM}" "${FETCH_ADDR}" "${VALIDATOR}" "${AMOUNT}${BOND_DENOM}" 
        echo "Added delegation from ${FETCH_ADDR} to ${VALIDATOR} of ${AMOUNT}${BOND_DENOM}"
    else
        echo "Skipped ${FETCH_ADDR} (${AMOUNT} < ${MIN_AMOUNT})"
    fi
done <<<$(cat "${CSV_FILE}" | sort)
