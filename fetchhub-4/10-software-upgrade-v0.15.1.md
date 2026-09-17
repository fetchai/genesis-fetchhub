# Software upgrade

This guide describes the procedure to upgrade to the `fetchd v0.15.1` following the [#41: Maintenance Upgrade](https://www.mintscan.io/fetchai/proposals/41) software upgrade governance proposal.

We kindly ask all validators and node operators to read through the following document carefully, and then wait until the chain reaches the upgrade block height `29254333` defined in the governance proposal *before* executing the upgrade steps.

In case of questions or issues, feel free to reach me on Discord (`@v0id.ptr`), or Telegram [@v0idptr](https://t.me/v0idptr).

# About the upgrade

The primary feature of this upgrade is the update of the `wasmvm` & `wasmd` libraries to the latest `rc3` versions.

> :warning: This is **\*binary-only\*** release. At this moment, it is **\*not\*** possible to build the node binary from the publicly accessible source code.
> The only way how to upgrade is to use either the provided docker image, or the precompiled binaries attached to the [v0.15.1 release](https://github.com/fetchai/fetchd/releases/tag/v0.15.1).

The node binary is provided only as **\*static (musl) linux build\*** for `x86_64` & `aarch64` CPU architectures, and is available in 2 forms:

 1. As publicly accessible docker image `fetchai/fetchd:v0.15.1-ae12a4f-musl` (it is a multi-platform image for both above mentioned CPU architectures)
 2. As precompiled static binaries attached to the [v0.15.1 release](https://github.com/fetchai/fetchd/releases/tag/v0.15.1) (for both above mentioned CPU architectures)

The precompiled static binaries attached in the [v0.15.1 release](https://github.com/fetchai/fetchd/releases/tag/v0.15.1) are **exactly the same (= identical)** as the binaries baked in the multi-platform docker image.

# Pre-requisites

## Enable full ASLR on the machine running your chain's executable [Not Mandatory, but highly recommended]
This is **\*not\*** a mandatory step, but we highly recommend to enable full ASLR (Address Space Layout Randomization) on the machine running your chain's executable, since it is a security feature that makes it harder for attackers to exploit memory corruption vulnerabilities.

To check if full ASLR is enabled on your node's machine, run the following command:

```shell
sysctl kernel.randomize_va_space
```

The output can be:

- `kernel.randomize_va_space = 0` - ASLR disabled
- `kernel.randomize_va_space = 1` - partial ASLR enabled
- `kernel.randomize_va_space = 2` - full ASLR enabled (the usual recommended setting)

Generally, all modern Linux kernels have full ASLR enabled (value `2`) by default.

If the output of the command above is `kernel.randomize_va_space = 2` you can skip the next step and continue with the [Upgrade procedure](#upgrade-procedure), otherwise please continue with step below to enable full ASLR on your node's machine before proceeding with the upgrade.

To explicitly set full ASLR (value `2`), use the following command:

```shell
sudo sysctl -w kernel.randomize_va_space=2
```

> :warning: The command above changes the setting only **\*temporarily\*** - the value will be lost after rebooting the node's machine. To make the full ASLR setting **\*persistent\*** across reboots, add the following line to the `/etc/sysctl.conf` file (or to a file inside the `/etc/sysctl.d/` directory, e.g. `/etc/sysctl.d/99-aslr.conf`, depending on your distribution):
> ```shell
> echo 'kernel.randomize_va_space=2' | sudo tee -a /etc/sysctl.conf
> ```
> , and then re-apply the settings:
> ```shell
> sudo sysctl --system
> ```

> :exclamation: Make sure that full ASLR (value `2`) is still enabled after rebooting the node's machine (e.g. verify the setting persists across reboots, or simply re-check it with the `sysctl kernel.randomize_va_space` command once the node is back up).

## Set environment variables
We would suggest to set the following environment variables, since they are used in the commands below:
> :warning: If you need to use quotes "..." in a value of the env var below **\*and\*** at the same time the ~ (tilde
> expansion variable), please do **\*not\*** include the ~ tilde expansion character in between quotes.
```shell
export FETCHD_HOME_DIR=~/.fetchd
export FETCHD_VERSION=v0.15.1
export FETCHD_TAG=v0.15.1-ae12a4f
export UPGRADE_TEMP_DIR=$(mktemp -d)
```

> :information_source: The `FETCHD_HOME_DIR` env variable is only needed if your node home directory is **\*not\*** the default (`~/.fetchd`) one, see the [Execute the upgrade](#execute-the-upgrade) section below.


# Upgrade procedure

## Chain halt
Wait until the blockchain reaches the target upgrade block height `29254333`, at which point all nodes will halt - it is **\*expected\*** to have an error logged by the node, similar to:

```
ERR UPGRADE "v0.15.1" NEEDED at height: 29254333: Update wasmvm & wasmd to the latest rc3
ERR CONSENSUS FAILURE!!! err="UPGRADE \"v0.15.1\" NEEDED at height: 29254333"
```

Once this happens, node operators can proceed with the installation of the new `v0.15.1` version of the `fetchd` executable.

## Choose the installation route
You can either use the docker image, or the precompiled binaries attached to the release:

### Option A: Docker image
Please use the `fetchai/fetchd:v0.15.1-ae12a4f-musl` docker image, it is available on Docker Hub. The image is a multi-platform image covering both `x86_64` & `aarch64` CPU architectures, so the very same image tag can be used on both platforms.

> :information_source: If you decide to go via the docker image route, this is where this guide **ends** for you - just replace the image tag of your current `fetchd` container (e.g. in your `docker-compose.yml` or systemd unit file) with the `v0.15.1-ae12a4f-musl` one, and (re)start the container as you usually do.

### Option B: Precompiled binaries
If you decide to go via the precompiled binaries route, follow the procedure below.

> :warning: The precompiled binaries are **\*static (musl) linux builds\*** only - there are no darwin (macOS), nor dynamically linked glibc builds available for this release.

## Detect CPU architecture & download the right binary
Detect your CPU architecture by running:
```shell
uname -m
```
It must print either `x86_64` or `aarch64`. Let's store it in an env variable, so that the commands below can be used as-is:
```shell
export ARCH=$(uname -m)
echo $ARCH
```

Now, download the correct archive (matching your CPU architecture) **and** the `sha256` checksums file from the [v0.15.1 release](https://github.com/fetchai/fetchd/releases/tag/v0.15.1) into the temporary location:
```shell
cd $UPGRADE_TEMP_DIR
curl -LO https://github.com/fetchai/fetchd/releases/download/v${FETCHD_VERSION#v}/fetchd_${FETCHD_TAG}_static_linux_${ARCH}.tgz
curl -LO https://github.com/fetchai/fetchd/releases/download/v${FETCHD_VERSION#v}/fetchd_${FETCHD_TAG}_static_linux.sha256.txt
```

At this point the temporary directory should contain the following 2 files:
```shell
ls -lh
```
```
-rw-r--r--  1 user user  500 Sep 17 02:27 fetchd_v0.15.1-ae12a4f_static_linux.sha256.txt
-rw-r--r--  1 user user  73M Sep 17 02:27 fetchd_v0.15.1-ae12a4f_static_linux_x86_64.tgz
```

## Unpack the fetchd binary
Unpack the downloaded archive (in the temporary location), which will produce the `fetchd` binary:
```shell
tar -xzvf fetchd_${FETCHD_TAG}_static_linux_${ARCH}.tgz
```
The archive contains the `fetchd` binary directly (it is **\*not\*** nested inside of a sub-directory), so after unpacking the temporary directory should contain:
```shell
ls -lh fetchd
```
```
-rwxr-xr-x  1 user user  200M Sep 17 02:27 fetchd
```

## Verify the sha256 checksum
Verify the `sha256` checksum of the unpacked `fetchd` binary against the checksums published in the `fetchd_${FETCHD_TAG}_static_linux.sha256.txt` file:
```shell
EXPECTED_SHA256=$(grep "static_linux_${ARCH}/fetchd" fetchd_${FETCHD_TAG}_static_linux.sha256.txt | awk '{print $NF}')
ACTUAL_SHA256=$(sha256sum fetchd | awk '{print $1}')
echo "expected: ${EXPECTED_SHA256}"
echo "actual:   ${ACTUAL_SHA256}"
```

The two values **MUST** be **\*identical\***. You can verify it programmatically as well:
```shell
if [ "${EXPECTED_SHA256}" = "${ACTUAL_SHA256}" ]; then echo "OK"; else echo "!!! CHECKSUM MISMATCH !!!"; fi
```

> :exclamation: If the checksums do **\*not\*** match, **\*do NOT proceed\*** with the installation - delete the temporary directory (`rm -rf $UPGRADE_TEMP_DIR`), re-download the archive and verify again.

For reference, these are the expected `sha256` checksums of the unpacked binaries (also provided in the `fetchd_${FETCHD_TAG}_static_linux.sha256.txt` file):
```
SHA256 (fetchd_v0.15.1-ae12a4f_static_linux_x86_64/fetchd) = 89c5f1c06c860a763506aa05e5a635d333a71e10fa5fe9be1b2148ae9f2e41ad
SHA256 (fetchd_v0.15.1-ae12a4f_static_linux_aarch64/fetchd) = 2b2848abc14ee0d3ac0a642477b58b1f7b261a959bf54f2aaabf28d07a38db8b
```

## Verify the version of the new (not yet installed) binary
Verify the version of the **\*unpacked\*** `fetchd` binary (from its temporary location, i.e. before installing it):
```shell
$UPGRADE_TEMP_DIR/fetchd version
```
> :exclamation: It **\*MUST\*** print exactly:
> ```
> v0.15.1-0-gae12a4f
> ```

## Verify the version of the libwasmvm library 
Verify the version of the libwasmvm library built-in the new (not yet installed) `fetchd` binary:
```shell
$UPGRADE_TEMP_DIR/fetchd query wasm libwasmvm-version
```
> :exclamation: It **\*MUST\*** print exactly:
> ```
> 3.0.8-rc.3
> ```


## Install the new fetchd binary

### Locate the current (old) fetchd binary
Find where the currently installed (=old) `fetchd` binary is located:
```shell
which fetchd
```
For example:
```
/usr/local/bin/fetchd
```
Store the location (and the old version) in env variables, so that the commands below can be used as-is:
```shell
export FETCHD_BIN_PATH=$(which fetchd)
export FETCHD_OLD_VERSION=$(fetchd version)
echo "fetchd is located at: ${FETCHD_BIN_PATH}, and its current version is: ${FETCHD_OLD_VERSION}"
```

### Back up the old fetchd binary
Back up the old binary by renaming it to `fetchd_<OLD_VERSION>`:
```shell
mv ${FETCHD_BIN_PATH} ${FETCHD_BIN_PATH}_${FETCHD_OLD_VERSION}
```
For example, if the old version is `v0.15.0`, this will create `/usr/local/bin/fetchd_v0.15.0` out of `/usr/local/bin/fetchd`.

### Copy the new fetchd binary into place
Copy the new `fetchd` binary from the temporary location to the location where the old `fetchd` binary was installed:
```shell
cp $UPGRADE_TEMP_DIR/fetchd ${FETCHD_BIN_PATH}
```

> :warning: If the old binary is installed in a system location (e.g. `/usr/local/bin`), the `mv` & `cp` commands above need to be run with `sudo`, i.e.:
> ```shell
> sudo mv ${FETCHD_BIN_PATH} ${FETCHD_BIN_PATH}_${FETCHD_OLD_VERSION}
> sudo cp $UPGRADE_TEMP_DIR/fetchd ${FETCHD_BIN_PATH}
> ```

## Verify the version of the newly installed binary
Verify the version of the **\*newly installed\*** `fetchd` binary - this time by simply invoking `fetchd version` **\*without\*** explicitly specifying its location, i.e. relying on the `fetchd` executable being resolved via the `PATH`:
```shell
hash -r
fetchd version
```
> :exclamation: It **\*MUST\*** print exactly:
> ```
> v0.15.1-0-gae12a4f
> ```

## Execute the upgrade
Simply start the **\*NEW\*** version (`v0.15.1`) of the `fetchd` node using the setup/configuration you usually use to start the node:

**\*IF\*** your node home directory is default (`~/.fetchd`) run the following command:
```shell
fetchd start
```
> , **\*OR\*** else provide the `--home $FETCHD_HOME_DIR` parameter (see the
> [Set environment variables](#set-environment-variables)`):
> ```shell
> fetchd --home $FETCHD_HOME_DIR start
> ```

## Monitor the node log
Monitor the log of your node. The line, like the one right below, must appear in the log, indicating that you are running the correct version of the `fetchd` node executable and that the upgrade is being applied:
```
INF applying upgrade "v0.15.1" at height: 29254333
```

Once you see lines like below being printed in the log, the upgrade procedure **has finished**:
```log
INF minted coins from module account amount=486881463nanomobx from=mint module=x/bank
INF minted coins from module account amount=4854128476nanonomx from=mint module=x/bank
INF minted coins from module account amount=6374048957362866375afet from=mint module=x/bank
INF executed block height=29254333 module=consensus num_invalid_txs=0 num_valid_txs=0
```

After this point, the node is just waiting until enough validators have upgraded & joined the network (with at least 2/3 of the global stake), after which the mainnet consensus will resume block generation on its own, and the mainnet upgrade procedure is finished from the conceptual standpoint.

You can also query your **local** RPC endpoint to verify that the right version is running and that the node properly restarted:
```shell
curl -s http://localhost:26657/abci_info | jq -r '.result.response.version'
```
> Make sure this prints exactly the `v0.15.1-0-gae12a4f` version.

Once the node is fully up & running and following the chain again, the temporary upgrade directory can be removed:
```shell
rm -rf $UPGRADE_TEMP_DIR
```
