import pandas as pd
from datetime import datetime, timezone
from google.cloud import bigquery
from collections import defaultdict
​
one_fet = int('1' + '0' * 18)
​
​
def do_query(client, query: str):
    query_job = client.query(query)
    iterator = query_job.result(timeout=30)
    rows = list(iterator)
​
    # Transform the rows into a nice pandas dataframe
    try:
        df = pd.DataFrame(data=[list(x.values()) for x in rows], columns=list(rows[0].keys()))
    except IndexError:
        print("Query returned no results")
        df = pd.DataFrame()
    return df
​
​
def process_table(df):
    if df.size == 0:
        return df
    df['block_timestamp'] = pd.to_datetime(df['block_timestamp'])
    df['principal'] = df['principal'].apply(int)
    df = df.sort_values(by=['block_number', 'log_index'])
    df.drop('contract_address', axis=1, inplace=True)
    return df
​
​
def execute_query(query: str):
    # get transactions from bigquery
    client = bigquery.Client()
    df = process_table(do_query(client, query))
    return df
​
​
def recover_staking_tx_events():
    staking_query = 'SELECT * FROM `blockchain-etl.ethereum_fetchai.{}`;'      
    staking_tables = ['Staking_event_BindStake', 'Staking_event_UnbindStake', 'Staking_event_Withdraw']
​
    return tuple(execute_query(staking_query.format(table)) for table in staking_tables)
​
​
def get_balances_at_time(bind,
                         unbind,
                         cut_off: datetime = datetime.max.astimezone(timezone.utc)):
    "returns balances at a particular point in time using the binding and unbinding staking events"
    balance = defaultdict(int)
    for _, row in bind.iterrows():
        if row['block_timestamp'] > cut_off:
            break
        balance[row['stakerAddress']] += row['principal'] 
​
    for _, row in unbind.iterrows():
        if row['block_timestamp'] > cut_off:
            break
        balance[row['stakerAddress']] -= row['principal'] 
    return balance
​
    
bind, unbind, _ = recover_staking_tx_events()
balance = get_balances_at_time(bind, unbind)
​
unique_addresses = len(balance)
total_bound = 0
total_holders = 0
​
for value in balance.values():
    total_bound += value
    if value >= one_fet:
        total_holders += 1
