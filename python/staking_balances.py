import pandas as pd
from datetime import datetime, timezone
from google.cloud import bigquery
from collections import defaultdict
import os
from web3 import Web3


class QueryWeb3:

    def __init__(self, target_network='mainnet'):
        assert target_network in {'mainnet', 'kovan'}, "unknown network"
        infura_id = os.environ['WEB3_INFURA_PROJECT_ID']
        self.w3 = Web3(Web3.HTTPProvider(f'https://{target_network}.infura.io/v3/{infura_id}'))
        self.block = None

    def is_contract(self, address):
        return len(self.w3.eth.getCode(self.w3.toChecksumAddress(address))) > 0

    def latest_block(self):
        return self.w3.eth.getBlock('latest')

    def get_block(self, block_number: int):
        assert isinstance(block_number, int)
        return self.w3.eth.getBlock(block_number)

    def latest_block_number(self):
        return self.latest_block()['number']


def do_query(client, query: str):
    query_job = client.query(query)
    iterator = query_job.result(timeout=30)
    rows = list(iterator)

    try:
        df = pd.DataFrame(data=[list(x.values()) for x in rows], columns=list(rows[0].keys()))
    except IndexError:
        print("Query returned no results")
        df = pd.DataFrame()
    return df


def process_table(df):
    if df.size == 0:
        return df
    df['block_timestamp'] = pd.to_datetime(df['block_timestamp'])
    df['principal'] = df['principal'].apply(int)
    df = df.sort_values(by=['block_number', 'log_index'])
    df.drop('contract_address', axis=1, inplace=True)
    return df


def execute_query(query: str):
    # get transactions from bigquery
    client = bigquery.Client()
    df = process_table(do_query(client, query))
    return df


def recover_staking_tx_events():
    staking_query = 'SELECT * FROM `blockchain-etl.ethereum_fetchai.{}`;'      
    staking_tables = ['Staking_event_BindStake', 'Staking_event_UnbindStake', 'Staking_event_Withdraw']

    return tuple(execute_query(staking_query.format(table)) for table in staking_tables)


def get_balances_at_time(bind,
                         unbind,
                         cut_off: datetime = datetime.max.astimezone(timezone.utc)):
    "returns balances at a particular point in time using the binding and unbinding staking events"
    balance = defaultdict(int)
    for _, row in bind.iterrows():
        if row['block_timestamp'] > cut_off:
            break
        balance[row['stakerAddress']] += row['principal'] 

    for _, row in unbind.iterrows():
        if row['block_timestamp'] > cut_off:
            break
        balance[row['stakerAddress']] -= row['principal'] 
    return balance


def write_iterable_to_file(filename: str, obj):
    assert hasattr(name, '__iter__'), "non iterable argument"
    with open(filename, 'w') as fp:
        for elem in obj:
            fp.write(elem)
            fp.write('\n')


def main():
    print('Querying BigQuery...')
    bind, unbind, _ = recover_staking_tx_events()
    balances = get_balances_at_time(bind, unbind)
    print('Writing contract balances...')
    pd.Series(balances).sort_index(ascending=True).to_csv('data/balances.csv')

    print('Testing address contract status...')
    qweb3 = QueryWeb3()
    unique_addresses = len(balances)
    total_bound = 0
    total_holders = 0
    contracts = set()

    for key in balances.keys():
        if qweb3.is_contract(key):
            contracts.add(key)

    print(f'Found: {len(contracts)} contract addresses.')
    if len(contracts) > 0:
        write_iterable_to_file('contract_addresses.txt', contracts)

if __name__ == "__main__":
    main()
