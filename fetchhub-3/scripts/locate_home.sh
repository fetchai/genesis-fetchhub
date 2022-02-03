#!/bin/bash

set -uo pipefail

usage() {
    echo "Lookup for fetchd home folders given a validator operator address (fetchvaloper...) inside a given base directory"
    echo -e "\nUsage: $0 [fetchvaloper...] [base_directory]\n" 
    exit 1
}

if [ $# -ne 2 ]; then
    usage
    exit 1
fi

LOOKUP_ADDR="$1"
SEARCH_DIR="$2"

if [ -z "${LOOKUP_ADDR}" ]; then
    usage
    exit 1
fi

if [[ ! "${LOOKUP_ADDR}" =~ ^fetchvaloper.* ]]; then
    echo "address prefix must be 'fetchvaloper'"
    usage
    exit 1
fi

if [[ ! -d "${SEARCH_DIR}" ]]; then
    echo "a search folder is required"
    usage
    
    exit 1
fi

# disable exit on errors as find will exit 1 when getting any permission denied
VAL_KEYS=($(find "${SEARCH_DIR}" -name priv_validator_key.json 2>/dev/null))

#echo "Found ${#VAL_KEYS[@]} potential FETCHD_HOME folders in ${SEARCH_DIR}"

HEX_ADDR=$(fetchd debug addr "${LOOKUP_ADDR}" 2>&1 | grep -oE "\s[A-Z0-9]{40}$")
for valKeyPath in "${VAL_KEYS[@]}"; do
    PUBKEY_ADDR=$(fetchd debug pubkey "$(jq -r '.pub_key.value' "${valKeyPath}" 2>/dev/null)" 2>&1 | grep -oE "\s[A-Z0-9]{40}$")
    if [ "${PUBKEY_ADDR}" == "${HEX_ADDR}" ]; then
        realpath "$(dirname "${valKeyPath}")/../"
    fi
done
