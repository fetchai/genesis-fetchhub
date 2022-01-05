# Capricorn Upgrade  

This repository contains steps and documentation aimed at **current mainnet validators** to migrate their nodes and upgrade the [Fetch.ai](https://fetch.ai) network to the latest (Capricorn) version of the software.

Validators can have a review on this repo docs and scripts, this should give a good idea what will happen. 
We'll still need to update few placeholders once we'll have the network ready to migrate but that's it.

In case of questions or issues, feel free to reach me on discord (@daeMOn).

## Timeline

### Pre migration

- Share this repository with validators on mainnet.
- Replace and adjust the last remaining placeholders in the procedure (`TODO_` items).

### Tuesday, January 11th 2022

- Submit a governance proposal for upgrading main-net.

### Tuesday, January 25th 2022

- Governance proposal for upgrading the network closes. If the proposal is passed, proceed with the upgrade steps below.
- Pause the smart contracts on both sides of the Fetch-Ethereum token bridge and shut-down relayer.

### Wednesday, January 26th 2020

- The network will pause at 14:00 UTC time: `2022-01-26T14:00:00Z`.
- The state from existing mainnet (`fetchhub-2`) will be exported, and used to create the base genesis file for the network upgrade.
- The following network parameters will be modified to enable IBC transfers on the upgraded mainnet, which will have a chain-id of `fetchhub-3`.

```json
{
    "app_state": {
        "staking": {
            "params": {
                "historical_entries": 10000
            }
        },
        "transfer": {
            "params": {
                "send_enabled": true,
                "receive_enabled": true
            }
        }
    }
}
```

In addition to this, `80616475991676767023462315` afet (around 80 million FET) will be burned from the foundation wallet address [fetch1c2wlfqn6eqqknpwcr0na43m9k6hux94dp6fx4y](https://explore-fetchhub.fetch.ai/account/fetch1c2wlfqn6eqqknpwcr0na43m9k6hux94dp6fx4y) to correct for tokens mistakenly minted at the previous network upgrade event.
