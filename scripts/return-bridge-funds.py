#!/usr/bin/env python3
import argparse
import json
import copy

TOKEN_BRIDGE_CONTRACT_ADDRESS = 'fetch18vd8fpwxzck93qlwghaj6arh4p7c5n890l3amr'
FOUNDATION_ADDRESS = 'fetch1m3evl6dqkhmwtp597wq8hhr9vtdasaktaq6wlj'
EXPECTED_TOKEN_BRIDGE_BALANCE = 141545184189144473545456630

def parse_commandline():
    parser = argparse.ArgumentParser()
    parser.add_argument('input_genesis')
    parser.add_argument('output_genesis')
    return parser.parse_args()


def main():
    args = parse_commandline()

    with open(args.input_genesis, 'r') as input_file:
        input_genesis = json.load(input_file)

    # Step 1. Iterate through and verify the token bridge balance
    token_bridge_contract_balance = None
    for entry in input_genesis['app_state']['bank']['balances']:
        if entry['address'] == TOKEN_BRIDGE_CONTRACT_ADDRESS:
            assert entry['coins'][0]['denom'] == 'afet'
            token_bridge_contract_balance = int(entry['coins'][0]['amount'])
            break

    assert token_bridge_contract_balance == EXPECTED_TOKEN_BRIDGE_BALANCE

    # Step 2. Generate the next set of accounts
    next_balances = []
    for entry in input_genesis['app_state']['bank']['balances']:
        if entry['address'] == TOKEN_BRIDGE_CONTRACT_ADDRESS:
            assert entry['coins'][0]['denom'] == 'afet'

            # balance is zero because it has been sent to the foundation
            entry['coins'][0]['amount'] = '0'

        elif entry['address'] == FOUNDATION_ADDRESS:
            assert entry['coins'][0]['denom'] == 'afet'

            # update the balance from the funds from the foundation
            current_amount = int(entry['coins'][0]['amount'])
            next_amount = current_amount + EXPECTED_TOKEN_BRIDGE_BALANCE

            entry['coins'][0]['amount'] = str(next_amount)

        next_balances.append(entry)

    # Step 3. Generate the updated genesis
    output_genesis = copy.deepcopy(input_genesis)
    output_genesis['app_state']['bank']['balances'] = next_balances

    with open(args.output_genesis, 'w') as output_file:
        json.dump(output_genesis, output_file, ensure_ascii=False, sort_keys=True)

if __name__ == '__main__':
    main()
