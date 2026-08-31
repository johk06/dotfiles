#!/usr/bin/env python

import psutil
import time
import json
import sys

UPPER_SENT=20 * 1024 * 1024
UPPER_RECV=30 * 1024 * 1024

sizes = ["B", "KB", "MB", "GB", "TB"]

def format_size(byte_value):
    for unit in sizes:
        if byte_value < 1024:
            return f"{byte_value:.1f}{unit}"
        byte_value /= 1024

def pos(n):
    return max(n, 0)

while True:
    net_stats_1 = psutil.net_io_counters()
    time.sleep(1)
    net_stats_2 = psutil.net_io_counters()

    diff_sent = net_stats_2[0] - net_stats_1[0]
    diff_recv = net_stats_2[1] - net_stats_1[1]

    json.dump({
        "total_sent_pretty": format_size(net_stats_2[0]),
        "total_recv_pretty": format_size(net_stats_2[1]),
        "sent_pretty": format_size(diff_sent),
        "recv_pretty": format_size(diff_recv),
        "sent_rel": pos((diff_sent / UPPER_SENT) * 100),
        "recv_rel": pos((diff_recv / UPPER_RECV) * 100),
        "sent": pos(diff_sent),
        "recv": pos(diff_recv)
    }, fp=sys.stdout)
    sys.stdout.write("\n")
    sys.stdout.flush()
