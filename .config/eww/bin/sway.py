#!/usr/bin/env python

import re
import i3ipc
import json

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

def safe_int(val):
    try:
        return int(val)
    except Exception:
        return 0

REGEX_NAMES = [
    ("^Minecraft.*", "minecraft"),
]

TERMINAL = "kitty"
TERM_OVERRIDES = [
    ("^nv:", "neovim"),
    ("^lf:", "file-manager"),
    ("^qalc$", "qalculator"),
    ("^btm$", "preferences-system-performance"),
    ("^pms$", "multimedia-audio-player"),
    ("^ncmpcpp", "multimedia-audio-player"),
    ("^aerc$", "email"),
    ("^newsboat$", "newsboat"),
]

CLASS_OVERRIDES = {
    "zenity": "dialog-info",
    "vesktop": "discord",
    "nm-connection-editor": "networkmanager",
}


def get_icon(icon_name, size=48, fallback="window-manager"):
    if not icon_name:
        icon_name = fallback
    icon_theme = Gtk.IconTheme.get_default()
    icon = icon_theme.lookup_icon(icon_name, size, 0)
    if icon:
        return icon.get_filename()
    else:
        return get_icon(None)


def dump_con(w: i3ipc.Con, output: i3ipc.Con):
    if not w or not w.pid:
        return None, False
    app_id = w.app_id or w.window_class or None
    app_id = CLASS_OVERRIDES.get(app_id, app_id)

    if app_id == TERMINAL:
        for override in TERM_OVERRIDES:
            if re.match(override[0], w.name):
                app_id = override[1]
    # overrides
    for override in REGEX_NAMES:
        if re.match(override[0], w.name):
            app_id = override[1]

    # past this point, we have no clue
    # give smth that at least helps us a bit
    if not app_id:
        if w.window_instance:
            app_id = "xorg"
        else:
            app_id = "wayland"

    rect = {"x": 0, "y": 0, "width": 0, "height": 0}

    width_scale = output.rect.width
    height_scale = output.rect.height

    rect["x"] = (w.rect.x - output.rect.x) / width_scale
    rect["y"] = (w.rect.y - output.rect.y) / height_scale

    rect["width"] = w.rect.width / width_scale
    rect["height"] = w.rect.height / height_scale

    win = {
        "float": w.type == "floating_con",
        "app_id": app_id,
        "id": w.id,
        "name": w.name,
        "pid": w.pid,
        "focused": w.focused,
        "rect": rect,
        "icon": get_icon(app_id),
        "marks": w.marks,
    }

    return win, w.focused


def get_for_ws(workspace: i3ipc.Con, output):
    on_ws = []
    is_active = False
    for w in workspace.descendants():
        if not w.pid:
            continue

        win, win_active = dump_con(w, output)
        if win_active:
            is_active = True
        on_ws.append(win)
    return sorted(on_ws, key=lambda w: w["float"]), is_active


def sort_by_name(ws):
    name = ws["ws"]
    if name[0] == "s":
        return safe_int(name[1:]) - 1000
    else:
        return safe_int(name)

def wsicon(name):
    if name[0] == "s":
        return chr(ord("α") + int(name[1:]) - 1)
    else:
        return str(name)

def update(i3, e):
    root = i3.get_tree()

    workspaces = []
    active_output = None
    for output in root.nodes:
        if output.name == "__i3":
            continue

        for workspace in output.nodes:
            windows, is_active = get_for_ws(workspace, output)
            if is_active:
                active_output = output
            ws = {
                "wins": windows,
                "focused": workspace.focused or is_active,
                "wsnum": workspace.num,
                "ws": workspace.name,
                "icon": wsicon(workspace.name),
                "is_virtual": False,
            }
            workspaces.append(ws)

    sorted_ws = sorted(workspaces, key=sort_by_name)

    if len(sorted_ws[-1]["wins"]) != 0:
        new_number = sorted_ws[-1]["wsnum"] + 1
        as_str = str(new_number)
        sorted_ws.append(
            {
                "wins": [],
                "focused": False,
                "icon": as_str,
                "wsnum": new_number,
                "ws": as_str,
                "is_virtual": True,
            }
        )

    active, _ = dump_con(root.find_focused(), active_output)
    print(
        json.dumps(
            {
                "active": active or None,
                "workspaces": sorted_ws,
                "scratch_count": len(root.scratchpad().floating_nodes),
            }
        ),
        flush=True,
    )


if __name__ == "__main__":
    i3 = i3ipc.Connection()
    update(i3, None)
    i3.on(i3ipc.Event.WINDOW, update)
    i3.on(i3ipc.Event.WORKSPACE_FOCUS, update)
    i3.main()
