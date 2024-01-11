
# Software upgrade

This guide is describing the procedure to upgrade to the [v0.11.3](https://github.com/fetchai/fetchd/releases/tag/v0.11.3) following the [software-upgrade proposal #25](https://explore-fetchhub.fetch.ai/proposals/25).

We kindly ask all the validators to read through the following document, and then wait for the upgrade block height `14699873` to be reached *before* executing the upgrade steps in order to upgrade their nodes.

In case of questions or issues, feel free to reach me on Discord (`@v0id.ptr`), or Telegram [@v0idptr](https://t.me/v0idptr).

## About the upgrade

The primary feature of this release is Municipal Inflation (detailed description of the feature is provided in the [PR #162 @ cosmos-sdk repository](https://github.com/fetchai/cosmos-sdk/pull/162)).
In this release, the Municipal Inflation is configured for the MOBX (3% APR) and NOMX (3% APR) tokens.

The secondary features are:
 * exposing pruning of cosmos-sdk application-DB as fetchd cli command, which can be executed manually while node is not running,
 * support for the Ledger Nano S-Plus HW,
 * enabling usage of Ledger HW wallets on macOS Ventura v13.x and higher

This is a breaking change release, which will require a chain restart due to the necessity of adding configuration for Municipal Inflation into the genesis mint module section. It will be rolled out via a software-upgrade governance proposal.

## Upgrade procedure

When mainnet blockchain reaches the target upgrade block height `14699873`, validator nodes will halt - it is **\*expected\*** to have an error logged by the node, similar to:

```
1:16PM ERR UPGRADE "v0.11.3" NEEDED at height: 14699873: Municipal Inflation v0.11.3 (upgrade-info)
1:16PM ERR CONSENSUS FAILURE!!! err="UPGRADE \"v0.11.3\" NEEDED at height: 14699873"
```

Once this happens, node operators can proceed with installation of the new `v0.11.3` version of the `fetchd` executable.

## Install new fetchd version

You may already have the fetchd repository on your machine from the previous installation. If not, you can:

```bash
git clone --branch v0.11.3 https://github.com/fetchai/fetchd fetchd_v0.11.3
cd fetchd_v0.11.3
```

If you already have an existing clone, place yourself in and:

```bash
git fetch
git clean -fd
git checkout v0.11.3
```

Now you can install the new fetchd version:

```bash
make install

# and verify you now have the correct version:
fetchd -h
# must print fetchd help message

fetchd version
# must print v0.11.3
```

Make sure the version is correct before proceeding further!

You're now ready to restart your node.

## Restarting fetchd

Fetchd can now be restarted. The exact commands depends on your particular setup (systemd, cosmovisor...)

On restart, it is expected to have a log line similar to:

```
1:31PM INF applying upgrade "v0.11.3." at height: 14699873
```

After this, your node should just hang and wait for more validators to complete the upgrade.
Once enough validators have upgraded & joined the network (with at least 2/3 of stake combined), the mainnet consensus will resume block generation on its own, and the mainnet upgrade procedure is finished from the conceptual standpoint.

## Verify upgrade completed

You can now query your local RPC endpoint to verify the right version is running and the node properly restarted:

```bash
curl -s http://localhost:26657/abci_info | jq -r '.result.response.version'
v0.11.3
```

Make sure this print exactly the `v0.11.3` version. If not, double check you're on the right git tag in the fetchd repository, that the `make install` didn't produce errors, and that your properly restarted your node.
