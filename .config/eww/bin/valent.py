#!/usr/bin/env python3

import json
import time

import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

BUS_NAME = "ca.andyholmes.Valent"
DEVICE = "ca.andyholmes.Valent.Device"
BUS_ROOT = "/ca/andyholmes/Valent"
INTROSPECT = "org.freedesktop.DBus.Introspectable"
PROPERTIES = "org.freedesktop.DBus.Properties"
ACTIONS = "org.gtk.Actions"
OBJECT_MANAGER = "org.freedesktop.DBus.ObjectManager"


DEVICES = {}


def do_reprint():
    devices = [dev.to_data() for dev in DEVICES.values()]
    connected = [dev for dev in devices if dev["connected"]]
    print(
        json.dumps(
            {
                "connected": connected,
                "devices": devices,
            }
        ),
        flush=True,
    )


class ValentDevice:
    def __init__(self, bus, path):
        self.path = path
        self.obj = bus.get_object(BUS_NAME, path)

        self.props = dbus.Interface(self.obj, dbus.PROPERTIES_IFACE)
        self.props.connect_to_signal("PropertiesChanged", self.update_properties)
        self.update_properties()

        self.actions = dbus.Interface(self.obj, ACTIONS)
        self.actions.connect_to_signal("Changed", self.update_actions)
        self.update_actions()

    def getprop(self, name):
        return self.props.Get(DEVICE, name)

    def update_properties(self, *args):
        self.name = self.getprop("Name")
        self.id = self.getprop("Id")
        self.state = self.getprop("State")

        do_reprint()

    def getaction(self, name):
        return self.actions.Describe(name)

    def update_actions(self, *args):
        self.battery = self.getaction("battery.state")[2][0]

        do_reprint()

    def is_connected(self):
        return self.state & 1 == 1

    def to_data(self):
        return {
            "path": self.path,
            "id": self.id,
            "name": self.name,
            "connected": self.is_connected(),
            "state": self.state,
            "battery": {
                "charging": bool(self.battery["charging"]),
                "percentage": self.battery["percentage"],
                "empty-in": self.battery["time-to-empty"],
            },
        }


def on_added(bus, devpath, *args):
    DEVICES[str(devpath)] = ValentDevice(bus, devpath)
    do_reprint()


def on_removed(bus, devpath, *args):
    DEVICES.pop(str(devpath))
    do_reprint()


def main():
    DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()

    bus.call_blocking(
        "org.freedesktop.DBus",
        "/org/freedesktop/DBus",
        "org.freedesktop.DBus",
        "StartServiceByName",
        "su",
        [BUS_NAME, 0],
    )
    time.sleep(2)

    valent = bus.get_object(BUS_NAME, BUS_ROOT)

    devices_iface = dbus.Interface(valent, OBJECT_MANAGER)
    devices_iface.connect_to_signal("InterfacesAdded", lambda *x: on_added(bus, x))
    devices_iface.connect_to_signal("InterfacesRemoved", lambda *x: on_removed(bus, x))

    for path in devices_iface.GetManagedObjects():
        DEVICES[str(path)] = ValentDevice(bus, path)


    do_reprint()

    loop = GLib.MainLoop()
    loop.run()


if __name__ == "__main__":
    main()
