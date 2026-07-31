#!/usr/bin/env python

import json
import subprocess
import sys


EVMAP = {
    "device.connected": "device",
    "device.added": "device",
    "battery.update": "battery",
    "battery.threshold": "battery",
    "mpris.update": "media",
    "sftp.mount": "sftp"
}

state = {}

proc = subprocess.Popen(
    ["kcd", "watch", "--json"], stdout=subprocess.PIPE, text=True, bufsize=1
)

for line in proc.stdout:
    obj = json.loads(line)
    ev = obj["type"]
    if ev in ("device.removed", "device.disconnected"):
        state[id] = None
    else:
        id = obj["deviceId"]
        if state.get(id) is None:
            state[id] = {}

        key = EVMAP.get(ev, ev)
        state[id][key] = obj["payload"]

    print(json.dumps(list(state.values())))
    sys.stdout.flush()
