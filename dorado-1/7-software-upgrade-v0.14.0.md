
# Software upgrade of testnet
The upgrade procedure is exactly the same as for mainnet [here](../fetchhub-4/7-software-upgrade-v0.14.0.md) with
following differences:

1. The eternal halt block height of CUDOS public **testnet** is `16128170`

2. Fetch Dorado testnet halt height is `14603003` 

3. In the [Executing Upgrade](../fetchhub-4/7-software-upgrade-v0.14.0.md#executing-upgrade) section, use the following
command instead:
   ```shell
   cd $FETCHD_HOME_DIR
   
   {==> CHANGE ME! (git tag) <==}
   git clone --branch v0.14.0 --depth 1 https://github.com/fetchai/genesis-fetchhub genesis-fetchhub
   
   cd genesis-fetchhub/fetchhub-4/data
   gzip -d -c e genesis.cudos.testnet.eternal_halt.json.gz > genesis.cudos.testnet.eternal_halt.json
   
   cd $FETCHD_HOME_DIR
   ```
   
   ```shell
   cd genesis-fetchhub/dorado-1/data

   {==> CHANGE ME! (HASH values) <==}
   fetchd --home $FETCHD_HOME_DIR start --cudos-genesis-path genesis.cudos.mainnet.eternal_halt.json --cudos-genesis-sha256    906ea6ea5b1ab5936bb9a5f350d11084eb92cba249e65e11c460ab251b27fb0e --cudos-migration-config-path cudos_merge_config.json --cudos-migration-config-sha256 2c48a252a051fb90a6401dffb718892084047a3f00dc99481d3692063cf65cce
   ```
