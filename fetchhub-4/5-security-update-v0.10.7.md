
# Software upgrade

This guide is describing the procedure to upgrade to [fetchd v0.10.7](https://github.com/fetchai/fetchd/releases/tag/v0.10.7) following the [software-upgrade proposal #6](https://explore-fetchhub.fetch.ai/proposals/6).

We kindly ask all the validators to read through the following document once, and then wait for the upgrade height (block #11235813) to be reached before executing the steps in order to upgrade their nodes.

In case of questions or issues, feel free to reach me on discord (@MissingNO57#3589).

## About the upgrade

This software upgrade is our first using the `x/upgrade` module to perform the upgrade. This should greatly simplify the process and reduce most manual operation the node operators have to perform. 

This imply that once the proposal passed, and the upgrade height is reached, **nodes will automatically stop** and require the new version to be installed in order to restart.

## Upgrade procedure

When reaching the target upgrade height, it is expected to have an error logged by the node, similar to:

```
1:16PM ERR UPGRADE "fetchd-v0.10.7" NEEDED at height: 11235813:
1:16PM ERR CONSENSUS FAILURE!!! err="UPGRADE \"fetchd-v0.10.7\" NEEDED at height: 11235813"
```

Once confirmed, the new version can be installed

## Install new fetchd version


You may already have the fetchd repository on your machine from the previous installation. If not, you can:

```bash
git clone --branch v0.10.7 https://github.com/fetchai/fetchd.git fetchd_0.10.7
cd fetchd_0.10.7
```

If you already have an existing clone, place yourself in and:

```bash
git fetch
git clean -fd
git checkout v0.10.7
```

Now you can install the new fetchd version:

```bash
make install

# and verify you now have the correct version:
fetchd -h
# must print fetchd help message

fetchd version
# must print v0.10.7
```

Make sure the version is correct before proceeding further!

You're now ready to restart your node.

## Restarting fetchd

Fetchd can now be restarted. The exact commands depends on your particular setup (systemd, cosmovisor...)

On restart, it is expected to have a log line similar to:

```
1:31PM INF applying upgrade "fetchd-v0.10.7" at height: 11235813
```

After this, your node should just hang, waiting for more people to complete the upgrade.
Once enought have proceeded, the block production should resume on its own, and this procedure is over.

## Verify upgrade completed

You can now query your local RPC endpoint to verify the right version is running and the node properly restarted:

```bash
curl -s http://localhost:26657/abci_info | jq -r '.result.response.version'
v0.10.7
```

Make sure this print `v0.10.7`, if not, double check you're on the right git tag in the fetchd repository, that the `make install` didn't produce errors, and that your properly restarted your node.
