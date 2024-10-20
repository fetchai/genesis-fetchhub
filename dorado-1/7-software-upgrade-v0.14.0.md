
# Software upgrade of testnet
The upgrade procedure is exactly the same as for mainnet [here](../fetchhub-4/7-software-upgrade-v0.14.0.md) with
following differences:

## CUDOS Eternal halt height
The eternal halt height for CUDOS public **testnet** is `16128170`

## Fetch network halt height
Fetch Dorado testnet halt height is `14603003` 

## Set primary environment variables:
In the [Set primary environment variables](../fetchhub-4/7-software-upgrade-v0.14.0.md#set-primary-environment-variables) section,
**\*INSTEAD\*** use the following commands to set values of the primary variables:
> :exclamation: Please **\*VERIFY\*** value of the FETCHD_HOME_DIR variable below and adjust it to correct directory of **\your*\***
> node **\IF*\*** it differs from default! 
```shell
# Please do *NOT* enclose value of this variable with double quotes, or with any quotation characters:
export FETCHD_HOME_DIR=~/.fetchd

export DESTINATION_CHAIN_ID="dorado-1"
export GENESIS_FETCHUB_GIT_REVISION="v0.14.0"

{==> CHANGE ME! (HASH value) <==}

export UPGRADE_SHA256_PARAMS="--cudos-genesis-sha256 906ea6ea5b1ab5936bb9a5f350d11084eb92cba249e65e11c460ab251b27fb0e --cudos-migration-config-sha256 2c48a252a051fb90a6401dffb718892084047a3f00dc99481d3692063cf65cce"
```
