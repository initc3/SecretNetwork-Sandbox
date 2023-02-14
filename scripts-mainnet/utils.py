import subprocess
import time
import json
import tempfile
import os
import sys
import random

from params_main import SECRETD, CHAIN_ID, PASSPHRASE, ATTACK_DIR, ADMIN

def unique_label():
    return str(time.time())

"""
For querying (simulated) contract state
"""
def query_contract(contract, query):
    query = json.dumps(query, separators=(',', ':'))
    cmd = f"{SECRETD} q compute query {contract} {json.dumps(query)}"
    return json.loads(subprocess.check_output(cmd, shell=True))

def query_native(addr):
    cmd = f"{SECRETD} query bank balances {addr}"
    return json.loads(subprocess.check_output(cmd, shell=True))

def _codehash(addr):
    cmd = f"{SECRETD} q compute contract-hash {addr}"
    r = subprocess.check_output(cmd, shell=True)
    return r[2:].decode('utf-8')

_codehashes={}
def get_codehash(addr):
    if addr not in _codehashes:
        _codehashes[addr] = _codehash(addr)
    return _codehashes[addr]


"""
For simulating transactions
"""

def generate_and_sign_tx(contract,sender,query,amount=0):
    codehash = get_codehash(contract)
    query = json.dumps(query, separators=(',', ':'))
    cmd = f"{SECRETD} tx compute execute --generate-only {contract} '{query}' --from {sender} --enclave-key io-master-cert.der --amount={amount}uscrt --chain-id={CHAIN_ID} --code-hash {codehash} --label {unique_label()} -y"
    tx_unsigned = subprocess.check_output(cmd, shell=True)
    tmpfile = "tmp.tx.json"
    open(tmpfile,'w').write(tx_unsigned.decode('utf-8'))
    cmd = f"echo {PASSPHRASE} | {SECRETD} tx sign {tmpfile} --from {sender} -y --keyring-backend=file --chain-id={CHAIN_ID}"
    tx_signed = subprocess.check_output(cmd, shell=True)
    os.remove(tmpfile)
    return tx_signed

def generate_and_sign_transfer(contract,sender,recp,amt):
    query = {"transfer":{"recipient":recp,"amount":str(amt),"memo":""}}
    r = generate_and_sign_tx(contract,sender,query)
    return r

def _clear_kvstore():
    try: os.remove(f"{ATTACK_DIR}/kv_store")
    except FileNotFoundError as e: pass
    open(f"{ATTACK_DIR}/kv_store",'w')

def _last_sim_kvstore():
    trace = list(open(f"{ATTACK_DIR}/kv_store").readlines())
    items = [(k[6:-2],v[8:-2]) for k,v in
             zip(trace[0::2],trace[1::2])]
    return items

def _last_sim_succeeded():
    return not int(open(f"{ATTACK_DIR}/simulate_result").read())

def simulate_tx(tx):
    TX_JSONFILE="tmp.tx.json"
    open(TX_JSONFILE,'w').write(tx.decode('utf-8'))
    cmd = f"echo {PASSPHRASE} | {SECRETD} tx compute simulatetx {TX_JSONFILE} --from {ADMIN} -y --keyring-backend=file"
    _clear_kvstore()
    r = subprocess.check_output(cmd, shell=True)
    os.remove(TX_JSONFILE)
    return _last_sim_kvstore() if _last_sim_succeeded() else None


"""
For replaying storage values
"""
def clear_outputs():
    files = [f"{ATTACK_DIR}/simulate_result",
             f"{ATTACK_DIR}/victim_key",
             f"{ATTACK_DIR}/adv_key",
             f"{ATTACK_DIR}/adv_value",
             f"{ATTACK_DIR}/kv_store"]
    for f in files:
        try:
            os.remove(f)
        except FileNotFoundError as e:
            print(e)
        open(f,'a')




"""
For managing snapshots
"""
def set_snapshot(snapname):
    cmd = f"""echo {PASSPHRASE} | {SECRETD} tx compute snapshot --from {ADMIN} --keyring-backend=file {snapname} -y"""
    subprocess.check_output(cmd, shell=True)
    # print("set_snapshot to:", snapname)

def clear_snapshot(snapname):
    cmd = f"""echo {PASSPHRASE} | {SECRETD} tx compute snapshot_clear --from {ADMIN} --keyring-backend=file {snapname} -y"""
    subprocess.check_output(cmd, shell=True)
    # print("clear snapshot:", snapname)



    
