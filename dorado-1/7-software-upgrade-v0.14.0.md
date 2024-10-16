
# Software upgrade of testnet
The upgrade procedure is exactly the same as for mainnet [here](../fetchhub-4/7-software-upgrade-v0.14.0.md) with
following differences:

1. The eternal halt block height of CUDOS public testnet is `16128170`

2. In the [Executing Upgrade](../fetchhub-4/7-software-upgrade-v0.14.0.md#executing-upgrade) section, use the following
command instead:
   ```shell
   cd $FETCHD_HOME_DIR
   git clone --branch v0.14.0 --depth 1 https://github.com/fetchai/genesis-fetchhub genesis-fetchhub
   7z e genesis-fetchhub/dorado-1/data/genesis.cudos.testnet__eternal_halt_height_16128170__2024.10.10_14.04.27Z.json.7z -o genesis-fetchhub/dorado-1/data
   ```
   ```shell
   {==> CHANGE ME! <==}
   
   fetchd --home $FETCHD_HOME_DIR start --cudos-genesis-path genesis-fetchhub/dorado-1/data/genesis.cudos.testnet__eternal_halt_height_16128170__2024.10.10_14.04.27Z.json --cudos-genesis-sha256 906ea6ea5b1ab5936bb9a5f350d11084eb92cba249e65e11c460ab251b27fb0e --cudos-migration-config-path genesis-fetchhub/dorado-1/data/cudos_merge_config.json --cudos-migration-config-sha256 2c48a252a051fb90a6401dffb718892084047a3f00dc99481d3692063cf65cce
   ```
