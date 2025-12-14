#!/usr/bin/env python

"""
This script serves as a sort of autotiling

It does a couple of things:
- Automatically change tiling direction based on window size -> spiral
- Add gaps when a workspace only contains one window
- Change scaling of main screen when in a specific workspace
"""

import i3ipc

# Configuration {{{
# target size of windows
SPLIT_RATIO = 1.61  # golden ratio
# gaps when there are multiple windows
DEFAULT_GAPS = 8
# gaps when there is only one window
SINGLE_GAPS = 32
# monitors to show gaps on if there only is one window
AUTO_GAPS_SCREENS = {"DP-1"}
# disable scaling when on this workspace
DISABLE_SCALING_ON_WS = 10
# scale to fall back to on all other workspaces
DEFAULT_SCALE = 1.4
# }}}


def switch_split_direction(i3: i3ipc.Connection, focused, e):
    if focused.type == "floating_con":
        return

    if focused.fullscreen_mode == 1:
        return

    if focused.parent.layout == "stacked" or focused.parent.layout == "tabbed":
        return

    new_layout = (
        "splitv" if focused.rect.height > focused.rect.width / SPLIT_RATIO else "splith"
    )
    if new_layout != focused.parent.layout:
        i3.command(new_layout)


def set_gaps(i3: i3ipc.Connection, gaps: int):
    i3.command(f"gaps outer current set {gaps}")


def adjust_gaps_on_ws(i3: i3ipc.Connection, focused, e: i3ipc.WindowEvent):
    if e.change not in ("new", "close", "floating", "move"):
        return
    ws = focused.workspace()
    screen = ws.parent
    if screen.name not in AUTO_GAPS_SCREENS:
        return

    gaps = screen.rect.width - ws.rect.width

    num_wins = len(ws.leaves())

    if num_wins > 1 and gaps != DEFAULT_GAPS:
        set_gaps(i3, DEFAULT_GAPS)
    elif num_wins == 1 and gaps != SINGLE_GAPS:
        set_gaps(i3, SINGLE_GAPS)


def on_win_change(i3: i3ipc.Connection, e):
    focused = i3.get_tree().find_focused()
    if not focused:
        return
    switch_split_direction(i3, focused, e)
    adjust_gaps_on_ws(i3, focused, e)


def workspace_based_scaling(i3: i3ipc.Connection, e: i3ipc.WorkspaceEvent):
    old_out = e.old.ipc_data["output"]
    new_out = e.current.ipc_data["output"]
    if old_out != new_out:
        return

    old_num = e.old.ipc_data["num"]
    new_num = e.current.ipc_data["num"]

    if not (old_num == DISABLE_SCALING_ON_WS or new_num == DISABLE_SCALING_ON_WS):
        return

    if old_num == DISABLE_SCALING_ON_WS:
        i3.command(f"output {new_out} scale {DEFAULT_SCALE}")
    else:
        i3.command(f"output {old_out} scale 1")


def main():
    i3 = i3ipc.Connection()
    i3.on(i3ipc.Event.WINDOW, on_win_change)
    i3.on(i3ipc.Event.WORKSPACE_FOCUS, workspace_based_scaling)
    i3.main()


if __name__ == "__main__":
    main()
