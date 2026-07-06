--[[ Synopsis {{{
  Flip the direction of the playlist 
  mainly useful to watch youtube playlists
  in chronological order.

  Credit to Willow Barraco (https://www.willowbarraco.fr/) in:
  https://git.sr.ht/~stacyharper/dotfiles/commit/1828bdea3db4607d297ea7d219f4894a6a6dbb0c
  See also:
  https://github.com/mpv-player/mpv/issues/8228

  Changes by me: Remove the global function (though that appears mpv's general style it irks me)
  Also: set the keybinding separately
}}} ]]

local function reverse_playlist()
    local count = mp.get_property_number("playlist-count")
    for i = 0, count, 1
    do
        mp.commandv("playlist-move", 0, count - i)
    end
    local newpos = mp.get_property_number("playlist-pos")
    mp.osd_message(
        ("Playlist Reversed: %d/%d"):format(newpos + 1, count)
        , 1
    )
end

--[[ NOTE: setting a mapping without a key just registers the action
  Mapping directly would cause it to get overridden by `no-input-default-bindings` which is set
  in mpv.conf ]]
mp.add_key_binding(nil, "reverse_playlist", reverse_playlist)
