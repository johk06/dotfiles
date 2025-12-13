"""
Suspend and background a process

Like pressing C-z and then running `bg` in one go
Only performs this action when the process is not the session leader
"""

import os
import time
import signal
from kitty.boss import Boss
from kittens.tui.handler import result_handler


def main(args: list[str]) -> str:
    pass


@result_handler(no_ui=True)
def handle_result(args: list[str], _: str, winid: int, boss: Boss) -> None:
    w = boss.window_id_map.get(winid)
    if w is None:
        return

    fgproc = w.child.foreground_processes[0]
    leader = w.child.pid

    # *never* mess with the session leader
    if not fgproc or fgproc["pid"] == leader:
        return

    w.send_key("ctrl+z")

    # give the process some time to process events before suspending
    # this is enough for neovim, so it should be enough for everything
    time.sleep(0.01)

    os.kill(fgproc["pid"], signal.SIGCONT)
