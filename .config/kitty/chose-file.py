from kitty.boss import Boss
from kittens.tui.handler import kitten_ui
import json
import subprocess


@kitten_ui(allow_remote_control=True)
def main(args: list[str]) -> None:
    out = subprocess.run(["lf", "-print-selection"], capture_output=True, text=True)
    if out.returncode == 0:
        return out.stdout.split("\n")
    else:
        return []

def relative_path_if_possible(path: str, base: str) -> str:
    if not base or not path:
        return path
    from contextlib import suppress
    from pathlib import Path
    b = Path(base)
    q = Path(path)
    with suppress(ValueError):
        return str(q.relative_to(b))
    return path

def needs_quoting(path: str) -> bool:
    return any(c in path for c in "\"' \t\n$!`")

def handle_result(
    args: list[str], data: list[str], target_window_id: int, boss: Boss
) -> None:
    import shlex
    w = boss.window_id_map.get(target_window_id)
    cwd = w.cwd_of_child

    items = []
    for path in data:
        if cwd:
            path = relative_path_if_possible(path, cwd)
        if w.at_prompt and needs_quoting(path):
            path = shlex.quote(path)
        items.append(path)
    
    text = (' ' if w.at_prompt else "\n").join(items)
    w.paste_text(text)
