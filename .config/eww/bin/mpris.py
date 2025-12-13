#!/usr/bin/env python
import json
import sys
from urllib.parse import urlparse, unquote
from pathlib import Path

import gi

gi.require_version("Playerctl", "2.0")
gi.require_version("Gtk", "3.0")

from gi.repository import GLib, Playerctl, Gtk

PLAYER_POSITIONS = {}

NAME_OVERRIDES = {"gapless": "com.github.neithern.g4music"}

LOOP_STATI = ["none", "track", "list"]


def get_icon(icon_name, size=48, fallback="multimedia-video-player"):
    if not icon_name:
        icon_name = fallback
    icon_theme = Gtk.IconTheme.get_default()
    icon = icon_theme.lookup_icon(icon_name, size, 0)
    if icon:
        return icon.get_filename()
    else:
        return get_icon(None)


def get_art(player):
    art_path = None
    try:
        art_url = player.props.metadata["mpris:artUrl"]
        if art_url.startswith("file://"):
            art_path = unquote(urlparse(art_url).path)
    except KeyError:
        art_path = None

    if not art_path or not Path(art_path).is_file():
        plname = player.props.player_name.lower()
        art_path = get_icon(NAME_OVERRIDES.get(plname, plname))

    return art_path


def do_meta(pl, *_):
    out = {}

    props = pl.props
    meta = props.metadata
    name = props.player_name
    out["has_player"] = True
    out["player"] = name
    out["playing"] = props.status == "Playing"
    position = PLAYER_POSITIONS.get(pl, 0)

    try:
        length = meta["mpris:length"]
    except KeyError:
        length = None

    out["art"] = get_art(pl)

    if length and position:
        out["has_progress"] = True
        out["length"] = int(length / 1000000)
        out["position"] = int(position / 1000000)
        out["progress"] = position / length
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

    sys.stdout.write(json.dumps(out) + "\n")
    sys.stdout.flush()


def on_play_pause(player, *_):
    do_meta(player)


def assert_not_none(man):
    if not len(man.props.player_names):
        sys.stdout.write(json.dumps({"has_player": False, "playing": False}) + "\n")
        sys.stdout.flush()
        return False
    return True


def on_new_or_disappear(man, name):
    if assert_not_none(man):
        init_player(name)


def poll_position():
    for pl in manager.props.players:
        if pl.props.playback_status == Playerctl.PlaybackStatus.PLAYING:
            PLAYER_POSITIONS[pl] = pl.get_position()
            do_meta(pl)
    return True


def init_player(name):
    player = Playerctl.Player.new_from_name(name)
    player.connect("metadata", do_meta, manager)
    player.connect("playback-status::playing", on_play_pause, manager)
    player.connect("playback-status::paused", on_play_pause, manager)
    player.connect("loop-status", do_meta, manager)
    player.connect("shuffle", do_meta, manager)
    manager.manage_player(player)


if __name__ == "__main__":
    manager = Playerctl.PlayerManager()
    manager.connect("name-appeared", on_new_or_disappear)
    manager.connect("name-vanished", on_new_or_disappear)

    [init_player(name) for name in manager.props.player_names]

    if assert_not_none(manager):
        player = Playerctl.Player()
        do_meta(player)

    GLib.timeout_add_seconds(1.5, poll_position)
    try:
        loop = GLib.MainLoop()
        loop.run()
    except (KeyboardInterrupt, Exception) as e:
        loop.quit()
