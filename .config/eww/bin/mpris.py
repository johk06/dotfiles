#!/usr/bin/env python
import json
import sys
from urllib.parse import urlparse, unquote
import os
import time
import gi

gi.require_version("Playerctl", "2.0")
gi.require_version("Gtk", "3.0")

from gi.repository import GLib, Playerctl, Gtk

NAME_OVERRIDES = {"gapless": "com.github.neithern.g4music"}

LOOP_STATI = ["none", "track", "list"]

LAST_CHANGED = None


def get_art(player):
    art_path = None
    try:
        art_url = player.props.metadata["mpris:artUrl"]
        if art_url.startswith("file://"):
            art_path = unquote(urlparse(art_url).path)
    except KeyError:
        art_path = None

    st = os.stat(art_path) if art_path else None
    if not art_path or not st or st.st_size == 0:
        return None

    return art_path


def get_meta(pl):
    out = {}
    props = pl.props
    meta = props.metadata
    name = props.player_name
    out["has_player"] = True
    out["player"] = name
    out["id"] = props.player_instance
    out["playing"] = props.status == "Playing"
    position = player.get_position()

    try:
        length = meta["mpris:length"]
    except KeyError:
        length = None

    out["art"] = get_art(pl)

    if length and position:
        out["has_progress"] = True
        out["length"] = int(length / 1000000)
        out["last_progress"] = position / length
        pos = int(position / 1000000)
        out["start_time"] = time.time() - pos
    else:
        out["has_progress"] = False

    out["loop"] = LOOP_STATI[props.loop_status]
    out["shuffle"] = props.shuffle

    try:
        artists = meta["xesam:artist"]
        num_artists = len(artists)
        if num_artists == 0:
            artist = None
        elif num_artists == 1:
            artist = artists[0]
        elif num_artists == 2:
            artist = "&".join(artists)
        else:
            artist = "&".join([",".join(artists[:-1]), artists[-1]])
        out["artist"] = artist
    except KeyError:
        out["artist"] = ""
    try:
        out["album"] = meta["xesam:album"]
    except KeyError:
        out["album"] = ""
    out["title"] = meta["xesam:title"]

    return out


def do_meta():
    players = [
        get_meta(pl)
        for pl in sorted(manager.props.players, key=lambda p: p != LAST_CHANGED)
    ]

    sys.stdout.write(json.dumps(players) + "\n")
    sys.stdout.flush()


def on_change(player, *_):
    global LAST_CHANGED
    LAST_CHANGED = player
    do_meta()

def on_seek(player, *_):
    time.sleep(0.5)
    on_change(player)


def assert_not_none(man):
    if not len(man.props.player_names):
        sys.stdout.write(json.dumps({"has_player": False, "playing": False}) + "\n")
        sys.stdout.flush()
        return False
    return True


def on_new_or_disappear(man, name):
    if assert_not_none(man):
        init_player(name)


def sync_timer():
    do_meta()

    return True


def init_player(name):
    player = Playerctl.Player.new_from_name(name)
    player.connect("metadata", on_change)
    player.connect("playback-status::playing", on_change)
    player.connect("playback-status::paused", on_change)
    player.connect("loop-status", on_change)
    player.connect("seeked", on_seek)
    player.connect("shuffle", on_change)
    manager.manage_player(player)

    if player.props.status == "Playing":
        global LAST_CHANGED
        LAST_CHANGED = player


if __name__ == "__main__":
    manager = Playerctl.PlayerManager()
    manager.connect("name-appeared", on_new_or_disappear)
    manager.connect("name-vanished", on_new_or_disappear)

    [init_player(name) for name in manager.props.player_names]

    if assert_not_none(manager):
        player = Playerctl.Player()
        sync_timer()

    GLib.timeout_add_seconds(10, sync_timer)
    try:
        loop = GLib.MainLoop()
        loop.run()
    except (KeyboardInterrupt, Exception) as e:
        loop.quit()
