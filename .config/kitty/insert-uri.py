from kitty.boss import Boss
from kitty.window import CommandOutput
from kittens.tui.handler import result_handler


def main(args: list[str]) -> str:
    pass

@result_handler(no_ui=True)
def handle_result(args: list[str], _: str, winid: int, boss: Boss) -> None:
    w = boss.window_id_map.get(winid)
    if w is None:
        return
    ans = w.cmd_output(
        CommandOutput.last_run,
    )

    w.write_to_child(ans)
