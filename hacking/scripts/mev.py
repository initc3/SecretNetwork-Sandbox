import os
import sys

from rich.console import Console
from rich.table import Table


def show_table(*, iteration, lines):
    table = Table(title=f"Bisection Search Iteration {iteration}")
    headers = lines[0].strip().split(", ")
    table.add_column("task", style="cyan")
    table.add_column("time (secs)", justify="right", style="green")

    for line in lines[1:]:
        line = line.strip().split(",")
        table.add_row(line[0], line[1])

    console = Console()
    console.print(table, justify="center")


if __name__ == "__main__":
    if len(sys.argv) == 3:
        with open(sys.argv[1]) as csvfile:
            lines = csvfile.readlines()
        show_table(iteration=sys.argv[2], lines=lines)

    else:
        print("Display content of csv file in a table.")
        print("Usage:\n\tpython mev.py csvfile iteration")
