from flask import Flask, request, jsonify
import flask
import requests
from binascii import unhexlify
import subprocess
import json
# import rocksdb
from flask import stream_with_context
import rocksdb

app = Flask(__name__)

"""
 Run with the following:
    flask --app server.py run -p 8001 --without-threads

 Note that single threaded is needed for now because of how 
  we rely on stateful file reading/writing to communicate with secretd 
"""

@app.route("/secret-4/snip20balance/sscrt/<addr>",methods=['GET'])
def fetch_balance(addr):
    ## Working with a local cache
    db = rocksdb.DB('accounts-scrt.db',
                    rocksdb.Options(create_if_missing=True))
    
    print(addr)
    assert(addr.startswith('secret1'))
    assert(len(addr) == 45)

    if db.get(addr.encode('utf-8')) is not None:
        log = db.get(addr.encode('utf-8'))
        return app.response_class(log,mimetype='text/event-stream')
    else:
        cmd = f"python infer_balance.py {addr}"
        print(cmd)
        p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, shell=True, close_fds=True);
        log = []
        def generate():
            for line in p.stdout:
                print(line)
                log.append(line)
                yield line

        response = app.response_class(stream_with_context(generate()),mimetype='text/event-stream')
        @response.call_on_close
        def on_close():
            p.kill()
            p.wait()
            if p.returncode == 0:
                db.put(addr.encode('utf-8'), b''.join(log))
        return response


    ## Working with an api
    # url = f"https://core.spartanapi.dev/secret/chains/pulsar-2/transactions/{txhash}"
    # r = requests.get(url)
    #print(r)
    #print(r.content)
    # global obj
    # obj = json.loads(r.content)
        
        # msgs = [msg['message']['msg'] if 'msg' in msg['message'] else
        #         msg['message']['init_msg'] if 'init_msg' in msg['message'] else '' for msg in obj['messages']]
        # #print(obj['tx']['value'])
        # #if 'msg' in obj['tx']['value']:
        # #    msgs = [msg['value']['msg'] for msg in obj['tx']['value']['msg']
        # #            if 'msg' in msg['value']]
        # response = flask.make_response(decrypt_tx(msgs))
        # response.headers.add('Access-Control-Allow-Origin', '*')
        # return response
    
@app.route("/pulsar-2/txsummary/<txhash>",methods=['GET'])
def fetch_txsummary(txhash):
    print(txhash, len(txhash))
    assert(len(txhash) == 64)
    url = f"https://core.spartanapi.dev/secret/chains/pulsar-2/transactions/{txhash}"
    r = requests.get(url)
    #print(r)
    #print(r.content)
    global obj
    obj = json.loads(r.content)
    
    msgs = [msg['message']['msg'] for msg in obj['messages']]
    decmsgs = decrypt_tx(msgs)
    
    response = flask.make_response(str(msgs) + '\n' + decmsgs)
    response.headers.add('Access-Control-Allow-Origin', '*')
    return response
