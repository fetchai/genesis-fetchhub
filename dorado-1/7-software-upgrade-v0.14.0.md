
# Software upgrade of testnet
The upgrade procedure is exactly the same as for mainnet [here](../fetchhub-4/7-software-upgrade-v0.14.0.md) with
following differences:

1. The eternal halt block height of CUDOS public **testnet** is `16128170`

2. Fetch Dorado testnet halt height is `14603003` 

3. In the [Set primary environment variables](../fetchhub-4/7-software-upgrade-v0.14.0.md#set-primary-environment-variables) section,
**\*INSTEAD\*** use the following commands to set values of the primary variables:
   ```shell
   export DESTINATION_CHAIN_ID="dorado-1"
   export GENESIS_FETCHUB_GIT_REVISION="v0.14.0"

   {==> CHANGE ME! (HASH value) <==}
   
   export UPGRADE_SHA256_PARAMS="--cudos-genesis-sha256 906ea6ea5b1ab5936bb9a5f350d11084eb92cba249e65e11c460ab251b27fb0e --cudos-migration-config-sha256 2c48a252a051fb90a6401dffb718892084047a3f00dc99481d3692063cf65cce"
   ```
