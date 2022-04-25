
# Security update

Due to the recent annoucement of [a security vulnerability in CosmWasm](https://github.com/CosmWasm/advisories/blob/main/CWAs/CWA-2022-003.md), we built [fetchd v0.10.3](https://github.com/fetchai/fetchd/releases/tag/v0.10.3) to address it.

We kindly ask all the validators to read through the following document once, and then take the steps in order to upgrade their nodes.

In case of questions or issues, feel free to reach me on discord (@daeMOn#5105).

## About the upgrade

This is a backward compatible - non consesus breaking change, meaning we don't need to halt the chain or perform any migration steps. The new version of the fetchd binary just need to be install and the node restarted to pick it up. 

This is required for all your node (validators, sentries and any other you may have)


## Install new fetchd version

You may already have the fetchd repository on your machine from the previous installation. If not, you can:

```bash
git clone --branch v0.10.3 https://github.com/fetchai/fetchd.git fetchd_0.10.3
cd fetchd_0.10.3
```

If you already have an existing clone, place yourself in and:

```bash
git fetch
git checkout v0.10.3
```

Now you can install the new fetchd version:

```bash
make install

# and verify you now have the correct version:
fetchd -h
# must print fetchd help message

fetchd version
# must print v0.10.3
```

Make sure the version is correct before proceeding further!

You're now ready to restart your node

## Verify upgrade completed

You can now query your local RPC endpoint to verify the right version is running and the node properly restarted:

```bash
curl -s http://localhost:26657/abci_info | jq -r '.result.response.version'
v0.10.3
```

Make sure this print `v0.10.3`, if not, double check you're on the right git tag in the fetchd repository, that the `make install` didn't produce errors, and that your properly restarted your node.
