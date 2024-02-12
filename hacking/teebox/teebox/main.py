import itertools
import json
import subprocess
import time

import typer
from typing_extensions import Annotated

from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.prompt import Prompt
from rich.style import Style
from rich.table import Table

console = Console(log_path=False)


class EnterPrompt(Prompt):
    prompt_suffix = ""


# env vars
ADMIN = "secret1fc3fzy78ttp0lwuujw7e52rhspxn8uj52zfyne"


app = typer.Typer()


@app.callback()
def callback():
    """
    Tool to demonstrate attacks as in SGXOnerated
    (https://eprint.iacr.org/2023/378).
    """


def _show_mev_stats(iteration, stats):
    tasks = [
        "bisection search single iteration",
        "restore database states",
        "generate and sign adversary transaction",
        "simulate front-running transaction",
        "query the liquidity pool before simulating the victim transation",
        "simulate victim transaction",
        "query the liquidity pool after simulating the victim transaction",
    ]
    table = Table(title=f"Bisection Search Iteration {iteration}")
    table.add_column("task", style="cyan")
    table.add_column("time (secs)", justify="right", style="green")

    times = stats.strip().split(",")

    for i, time in enumerate(times):
        table.add_row(tasks[i], time)

    console.print(table, justify="center")


@app.command()
def print_json(jsonfile: str):
    with open(jsonfile) as f:
        content = f.read()
    console.print_json(content)


@app.command()
def info_panel(
    text: str,
    title: Annotated[str, typer.Option()] = "",
):
    console.print(
        Panel.fit(text, title=f"[bold]{title}[/]", border_style="blue"),
        justify="center",
    )


@app.command()
def log(text: str):
    console.log(text)


@app.command()
def show_mev_stats(csvfile):
    with open(csvfile) as f:
        lines = f.readlines()

    console.print(
        Panel.fit(
            ":watch: [bold]Time measurements for each iteration of the bisection search[/] :watch:",
            title="[bold]Stats Time[/]",
            border_style="blue",
        ),
        justify="center",
    )

    for i, stats in enumerate(lines):
        _ = EnterPrompt.ask(
            f"\n[bold red]Press enter to see the time measurements of the {i}th iteration[/]\n"
        )

        _show_mev_stats(i, stats)


@app.command()
def restore_db():
    """
    Restore database
    """
    typer.echo("Restore database")


def wait_for_tx():
    """
    TX=""
    while [ "$TX" == "" ]; do
      sleep 1
      log "wait for tx"
      TX=$($SECRETD q tx $1)
    done
    """


@app.command()
def init_contract():
    """
    Initialize a secret network contract.
    """
    # log "Storing contract"
    # STORE_TX=$($SECRETD tx compute store $CONTRACT_LOC/$OBJ --from $ADMIN -y --broadcast-mode sync --gas=5000000)
    # eval STORE_TX_HASH=$(echo $STORE_TX | jq .txhash )
    # wait_for_tx $STORE_TX_HASH
    # eval CODE_ID=$($SECRETD q tx $STORE_TX_HASH | jq ".logs[].events[].attributes[] | select(.key==\"code_id\") | .value ")

    # log "Instantiating contract"
    # INIT_TX=$($SECRETD tx compute instantiate $CODE_ID $1 --from $ADMIN --label $UNIQUE_LABEL -y --broadcast-mode sync )
    # eval INIT_TX_HASH=$(echo $INIT_TX | jq .txhash )
    # wait_for_tx $INIT_TX_HASH
    # eval CONTRACT_ADDRESS=$($SECRETD q tx $INIT_TX_HASH | jq ".logs[].events[] | select(.type==\"instantiate\") | .attributes[] | select(.key==\"contract_address\") | .value ")
    # echo $CONTRACT_ADDRESS > $CONTRACT_LOC/contractAddress.txt

    # eval CODE_HASH=$($SECRETD q compute contract-hash $CONTRACT_ADDRESS)
    # CODE_HASH=${CODE_HASH:2} #strip of 0x.. from CODE_HASH hex string
    # echo $CODE_HASH > $CONTRACT_LOC/codeHash.txt
    typer.echo("init contract")


@app.command()
def generate_and_sign_tx():
    """
    Generate and sign a transaction.
    """
    typer.echo("generate and sign tx")
    # $SECRETD tx compute execute $CONTRACT_ADDRESS --generate-only $1 --from $2 --enclave-key io-master-key.txt --code-hash $CODE_HASH --label $UNIQUE_LABEL -y --broadcast-mode sync > tx_$3.json
    # $SECRETD tx sign tx_$3.json --chain-id $CHAIN_ID --from $2 -y > tx_$3_sign.json


@app.command()
def generate_and_sign_transfer():
    """
    generate_and_sign_transfer
    """
    # generate_and_sign_tx "{\"transfer\":{\"recipient\":\"$2\",\"amount\":\"$3\",\"memo\":\"\"}}" $1 $4
    typer.echo("generate and sign transfer")


@app.command()
def simulate_tx():
    """
    Simulate a transaction.
    """
    # $SECRETD tx compute simulatetx tx_$1_sign.json --from $ADMIN -y > /dev/null
    typer.echo("simulate tx")


@app.command()
def execute_tx():
    """
    Execute a transaction.
    """
    # {
    #    TX=$($SECRETD tx compute execute $CONTRACT_ADDRESS $1  --from $2 -y)
    #    eval TX_HASH=$(echo $TX | jq .txhash )
    #    wait_for_tx $TX_HASH
    # }
    typer.echo("execute tx")


@app.command()
def set_snapshot(signer: str, label: str):
    """
    Set snapshot.
    """
    subprocess.run(
        [
            "secretd",
            "tx",
            "compute",
            "snapshot",
            "--from",
            signer,
            f"snapshot{label}",
            "-y",
            "--broadcast-mode",
            "sync",
        ],
        capture_output=True,
    )


@app.command()
def reset_snapshot():
    """
    Reset snapshot.
    """
    # {
    #    $SECRETD tx compute snapshot --from $ADMIN "" -y --broadcast-mode sync
    #    log "reset_snapshot to default dbstore"
    # }
    typer.echo("reset snapshot")


@app.command()
def broadcast_tx():
    """
    Broadcast a transaction.
    """
    # {
    #    TX=$($SECRETD tx broadcast tx_$1_sign.json --from $ADMIN -y)
    #    eval TX_HASH=$(echo $TX | jq .txhash )
    #    wait_for_tx $TX_HASH
    # }
    typer.echo("broadcast tx")


def _query_contract_state(contract_address, query):
    """
    Query the contract state.
    """
    completed_process = subprocess.run(
        ["secretd", "q", "compute", "query", contract_address, query],
        capture_output=True,
    )
    return completed_process.stdout.decode().strip()


VICTIM = "secret1ldjxljw7v4vk6zhyduywh04hpj0jdwxsmrlatf"
ADV = "secret1ajz54hz8azwuy34qwy9fkjnfcrvf0dzswy0lqq"

CONTRACT_LOC = "contract-toy-swap"
OBJ = "contract.wasm"


@app.command()
def init_toy_swap_contract():
    """ """
    # {
    #    init_contract "{\"init\":{\"pool_a\":$1,\"pool_b\":$2}}"
    # }


@app.command()
def set_balance():
    """ """
    # {
    #    execute_tx "{\"init_balance\":{\"token_type\":\"$1\",\"user\":\"$2\",\"balance\":$3}}" $ADMIN
    # }


@app.command()
def prepare():
    """ """
    # {
    #    init_toy_swap_contract 1000 2000
    #    set_balance token_a $VICTIM 100
    #    set_balance token_b $VICTIM 100
    #    set_balance token_a $ADV 100
    #    set_balance token_b $ADV 100
    # }


@app.command()
def generate_and_sign_swap():
    """ """
    # {
    #    generate_and_sign_tx "{\"swap\":{\"token_type\":\"$1\",\"offer_amt\":$2,\"expected_return_amt\":$3,\"receiver\":\"$4\"}}" $4 $5
    # }


@app.command()
def query_pool(contract_address, pool):
    """ """
    # {
    #    size=$(query_contract_state "{\"$1\":{}}")
    #    echo $size
    # }
    return _query_contract_state(contract_address, json.dumps({pool: {}}))


def _query_balance(contract_address, user, token_type):
    """ """
    #    balance=$(query_contract_state "{\"balance\":{\"token_type\":\"$1\",\"user\":\"$2\"}}")
    query = {"balance": {"token_type": token_type, "user": user}}
    balance = _query_contract_state(contract_address, json.dumps(query))

    # TODO
    # log "query_balance", token_type, user, balance
    # console.log("[blue]query_balance[/]", token_type, f"[yellow]{user}[/]", balance)

    return balance


@app.command()
def query_balances(
    contract_address,
    show_table: Annotated[bool, typer.Option()] = False,
    table_title: Annotated[str, typer.Option()] = None,
):
    """ """
    g = tuple(itertools.product((VICTIM, ADV), ("token_a", "token_b")))
    balances = {VICTIM: {"label": "victim"}, ADV: {"label": "attacker"}}

    for user_address, token_type in g:
        balances[user_address][token_type] = _query_balance(
            contract_address, user_address, token_type
        )

    if not show_table:
        return

    if not table_title:
        table_title = "Balances"

    # title_style = Style(color=None, bgcolor="grey50", bold=True)
    title_style = Style(italic=True, bold=True)
    table = Table(title=table_title, title_style=title_style)
    table.add_column("user", style="blue")
    table.add_column("user address", style="yellow")
    table.add_column("token type", style="cyan")
    table.add_column("balance")

    for user_address, token_type in g:
        table.add_row(
            balances[user_address]["label"],
            user_address,
            token_type,
            balances[user_address][token_type],
        )

    console.print(table, justify="center")


@app.command()
def query_pools(
    contract_address,
    show_table: Annotated[bool, typer.Option()] = False,
    table_title: Annotated[str, typer.Option()] = None,
):
    """ """
    pool_a = _query_contract_state(contract_address, json.dumps({"pool_a": {}}))
    pool_b = _query_contract_state(contract_address, json.dumps({"pool_b": {}}))

    if not show_table:
        return

    if not table_title:
        table_title = "Liquidity Pool Balances"

    # title_style = Style(color=None, bgcolor="grey50", bold=True)
    title_style = Style(italic=True, bold=True)
    table = Table(title=table_title, title_style=title_style)
    table.add_column("Pool", style="blue")
    table.add_column("Balance", style="yellow")

    table.add_row("Pool for Token A", pool_a)
    table.add_row("Pool for Token B", pool_b)

    console.print(table, justify="center")
