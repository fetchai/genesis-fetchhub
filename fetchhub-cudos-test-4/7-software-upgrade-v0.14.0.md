
# Software upgrade of testnet
The upgrade procedure is exactly the same as for mainnet [here](../fetchhub-4/7-software-upgrade-v0.14.0.md) with
following differences:

1. Genesis for this test was exported from CUDOS public MAINNET at the `12241907` block height. It is supposed to be
used **\*exclusively\*** for testing purposes, since it is *not* the final genesis.

2. Halt height of the **\*private\*** Fetch Mainnet **test** network is `18787814` 

3. In the [Set primary environment variables](../fetchhub-4/7-software-upgrade-v0.14.0.md#set-primary-environment-variables) section,
**\*INSTEAD\*** use the following commands to set values of the primary variables:
   ```shell
   export DESTINATION_CHAIN_ID="fetchhub-cudos-test-4"

   {==> CHANGE ME! (HASH value) <==}
   
   export UPGRADE_SHA256_PARAMS="--cudos-genesis-sha256 a3a00569e4ece61051e12355d47ad345576dba6a10c72c54e6985f46da37ee77 --cudos-migration-config-sha256 a070402dd3fb79e67bc3b6a044b91380c874a566ce6f287bfe2406d0caa1711a"
   ```
