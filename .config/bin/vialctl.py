#!/usr/bin/env python

import hid
import argparse
import struct
import colorsys
import sys
import re

VIAL_SERIAL_MAGIC = "vial:f64c2b3c"


class VialCmd:
    SET_LIGHTING = 0x07
    GET_LIGHTING = 0x08


# only those i care about rn
ANIMATIONS = {
    "off": 0,
    "direct": 1,
    "solid": 2,
    "breathe": 6,
    "spiral": 12,
    "color_cycle": 13,
    "cycle_lr": 14,
    "cycle_ud": 15,
    "rainbow_chevron": 16,
    "rainbow_wave": 17,
    "dual_rainbow_wave": 18,
    "rainbow_cycle": 19,
    "rainbow_spiral": 20,
    "rainbow_glow": 21,
    "glow_spiral": 22,
    "jellybeans": 25,
    "heatmap": 29,
    "rain": 30,
    "keypress": 31,
    "splash": 34,
    "linear_splash": 38,
    "wave": 39,
    "wave_mono": 41,
    "colors": 43,
}

CODES2ANIMS = {v: k for k, v in ANIMATIONS.items()}

COLORNAMES = {
    # colors i really like
    "copper": (0xD4, 0x3E, 0x1B),
    "green": (0xBE, 0x7E, 0x22),
    "rose": (0xFF, 0x20, 0x20),
    # and standard colors
    "red": (0xFF, 0x00, 0x00),
    "purple": (0xFF, 0x00, 0x5A),
}


def is_rawhid(dev: hid.DeviceInfo):
    return not (dev["usage_page"] != 0xFF60 or dev["usage"] != 0x61)


def find_vial_devices() -> list[hid.DeviceInfo]:
    res: list[hid.DeviceInfo] = []
    for dev in hid.enumerate():
        if VIAL_SERIAL_MAGIC in dev["serial_number"] and is_rawhid(dev):
            res.append(dev)

    return res


class VialKbd:
    def __init__(self, dev: hid.DeviceInfo):
        self.desc = dev
        self.max_brightness = self.cur_speed = self.cur_mode = 0
        self.cur_hsv = (0, 0, 0)
        self.supported_anims = {0}
        self.get_color_info()

    def msg(self, data: bytes) -> bytes:
        if len(data) > 32:
            raise RuntimeError("Message length must be 32 bytes")

        data += b"\x00" * (32 - len(data))  # padd
        with hid.Device(path=self.desc["path"]) as dev:
            num_written = dev.write(b"\x00" + data)
            response = dev.read(32, timeout=500)

        return response

    def get_color_info(self):
        data = self.msg(struct.pack("BB", VialCmd.GET_LIGHTING, 0x40))[2:]

        rgb_version = data[0] | (data[1] << 8)
        assert rgb_version == 1

        self.max_brightness = data[2]
        max_effect = 0
        while max_effect < 0xFFFF:
            data = self.msg(
                struct.pack("<BBH", VialCmd.GET_LIGHTING, 0x42, max_effect)
            )[2:]
            for x in range(0, len(data), 2):
                value = int.from_bytes(data[x : x + 2], byteorder="little")
                if value != 0xFFFF:
                    self.supported_anims.add(value)
                max_effect = max(max_effect, value)
        data = self.msg(struct.pack("BB", VialCmd.GET_LIGHTING, 0x41))[2:]
        self.cur_mode = int.from_bytes(data[0:2], byteorder="little")
        self.cur_speed = data[2]
        self.cur_hsv = (data[3], data[4], data[5])

    def set_color(self, r: int, g: int, b: int):
        r_scaled, g_scaled, b_scaled = r / 255.0, g / 255.0, b / 255.0
        h, s, v = colorsys.rgb_to_hsv(r_scaled, g_scaled, b_scaled)
        h, s, v = int(h * 255), int(s * 255), int(v * 255)

        self.cur_hsv = (h, s, v)

        self.msg(
            struct.pack(
                "BBHBBBB",
                VialCmd.SET_LIGHTING,
                0x41,
                self.cur_mode,
                self.cur_speed,
                h,
                s,
                v,
            )
        )

    def set_animation(self, anim: int, speed: int or None):
        if anim not in self.supported_anims:
            raise RuntimeError("Animation not supported by device")

        self.cur_mode = (anim,)
        if speed:
            self.cur_speed = speed

        self.msg(
            struct.pack(
                "BBHBBBB",
                VialCmd.SET_LIGHTING,
                0x41,
                anim,
                speed or self.cur_speed,
                self.cur_hsv[0],
                self.cur_hsv[1],
                self.cur_hsv[2],
            )
        )


def parse_hex_color(hex: str) -> (int, int, int):
    str = hex.lstrip("#")

    r = int(str[0:2], 16)
    g = int(str[2:4], 16)
    b = int(str[4:6], 16)

    return r, g, b


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-l", "--list", action="store_true")
    parser.add_argument("-c", "--color", metavar="[#]RRGGBB[AA]")
    parser.add_argument("-a", "--animation", metavar="animation[:speed[%]]")
    parser.add_argument(
        "-L", "--list-animations", action="store_true", dest="list_animations"
    )
    parser.add_argument("-C", "--get-color", action="store_true", dest="get_color")
    args = parser.parse_args()

    devs = find_vial_devices()
    if len(devs) == 0:
        print("No devices found", file=sys.stderr)
        exit(1)

    if args.list:
        for dev in devs:
            print(f"{dev['path'].decode()} {dev['product_string']}")

    kbds = [VialKbd(dev) for dev in devs]

    if args.list_animations:
        for kbd in kbds:
            print(
                f"{kbd.desc['product_string']}: {', '.join([CODES2ANIMS[an] for an in kbd.supported_anims])}"
            )

    if args.color:
        if args.color in COLORNAMES:
            color = COLORNAMES[args.color]
        else:
            color = parse_hex_color(args.color)
        for kbd in kbds:
            kbd.set_color(*color)

    if args.animation:
        split = args.animation.split(":")
        anim = split[0]
        speed = len(split) > 1 and split[1] or None
        if re.match(r"\d+", anim):
            animcode = int(anim)
        else:
            animcode = ANIMATIONS.get(anim, None)
            if animcode is None:
                print("Animation does not exist: " + anim, file=sys.stderr)
                exit(1)
        if speed:
            speed = int(speed.rstrip("%"))
            speed = int((speed * 255) / 100)
        for kbd in kbds:
            kbd.set_animation(animcode, speed or None)

    if args.get_color:
        for kbd in kbds:
            r, g, b = colorsys.hsv_to_rgb(
                kbd.cur_hsv[0] / 255.0, kbd.cur_hsv[1] / 255.0, kbd.cur_hsv[2] / 255.0
            )
            r = int(round(r * 255))
            g = int(round(g * 255))
            b = int(round(b * 255))
            print(f"#{r:02X}{g:02X}{b:02X}")


if __name__ == "__main__":
    main()
