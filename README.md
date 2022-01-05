# Capricorn Upgrade  

This repository contains steps and documentation aimed to **current mainnet validators** in order to migrate their nodes and upgrading the network to latest (Capricorn) version of the  

Validators can have a review on this repo docs and scripts, this should give a good idea what will happen. 
We'll still need to update few placeholders once we'll have the network ready to migrate but that's it.

In case of questions or issues, feel free to reach me on discord (@daeMOn).

## Timeline

### Pre migration

- Share this repository with validators on mainnet (chain-id=fetchhub-2)
- Replace and adjust the last remaining placeholders in the procedure (`TODO_` items)

### Tuesday, January 11th 2022

- Submit a governance proposal for upgrading the [Fetch.ai](https://fetch.ai) main-net. 

### Tuesday, January 25th 2022

- Governance proposal for upgrading the network closes. If the proposal is passed, proceed with the upgrade steps below 
- Pause the smart contracts on both sides of the Fetch-Ethereum token bridge and shut-down relayer

### Wednesday, January 26th 2020

- The network will pause at: `2022-01-26T14:00:00Z`
- The genesis state from existing mainnet (fetchhub-2) will be exported
- The following network parameters will be modified to enable IBC transfers on the upgraded mainnet, which will have a chain-id of fetchhub-3. 

```
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
