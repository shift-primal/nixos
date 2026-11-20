#!/usr/bin/env python3
"""Log keyboard chatter (one key firing twice within a few ms) and per-key press totals.

Totals are counts per key with no order or timing, so typed text is never recorded.
A press that fires twice counts as one press and one double.
Key names are physical US positions, e.g. SEMICOLON is the key right of L.
"""

import argparse
import glob
import os
import selectors
import signal
import struct
import sys
import time
from collections import Counter
from datetime import datetime
from pathlib import Path

EVENT = struct.Struct("qqHHi")
EV_KEY = 1
RELEASE, PRESS = 0, 1
SAVE_EVERY = 60

NAMES = dict(
    enumerate(
        """ESC 1 2 3 4 5 6 7 8 9 0 MINUS EQUAL BACKSPACE TAB
        Q W E R T Y U I O P LEFTBRACE RIGHTBRACE ENTER LEFTCTRL
        A S D F G H J K L SEMICOLON APOSTROPHE GRAVE LEFTSHIFT BACKSLASH
        Z X C V B N M COMMA DOT SLASH RIGHTSHIFT KPASTERISK LEFTALT SPACE CAPSLOCK
        F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 NUMLOCK SCROLLLOCK
        KP7 KP8 KP9 KPMINUS KP4 KP5 KP6 KPPLUS KP1 KP2 KP3 KP0 KPDOT""".split(),
        start=1,
    )
) | {
    86: "102ND",
    87: "F11",
    88: "F12",
    96: "KPENTER",
    97: "RIGHTCTRL",
    98: "KPSLASH",
    99: "SYSRQ",
    100: "RIGHTALT",
    102: "HOME",
    103: "UP",
    104: "PAGEUP",
    105: "LEFT",
    106: "RIGHT",
    107: "END",
    108: "DOWN",
    109: "PAGEDOWN",
    110: "INSERT",
    111: "DELETE",
    125: "LEFTMETA",
    126: "RIGHTMETA",
    127: "COMPOSE",
}


def load_totals(path):
    presses, doubles = Counter(), Counter()
    if path.exists():
        for row in path.read_text().splitlines()[2:]:
            name, pressed, doubled, _ = row.split()
            presses[name], doubles[name] = int(pressed), int(doubled)
    return presses, doubles


def save_totals(path, presses, doubles):
    def rate(pressed, doubled):
        return f"{100 * doubled / max(pressed, 1):.2f}%"

    total_presses, total_doubles = presses.total(), doubles.total()
    lines = [
        f"{total_presses} presses, {total_doubles} doubles ({rate(total_presses, total_doubles)})",
        f"{'key':<14} {'presses':>10} {'doubles':>8} {'rate':>8}",
    ]
    for name in sorted(presses, key=lambda name: (-doubles[name], -presses[name])):
        lines.append(
            f"{name:<14} {presses[name]:>10} {doubles[name]:>8} {rate(presses[name], doubles[name]):>8}"
        )

    temporary = path.with_suffix(".tmp")
    temporary.write_text("\n".join(lines) + "\n")
    os.replace(temporary, path)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--threshold", type=float, default=50, help="max ms between presses (default 50)"
    )
    parser.add_argument("--log", type=Path, default=Path.home() / "chatter.log")
    parser.add_argument("--totals", type=Path, default=Path.home() / "chatter-totals.txt")
    parser.add_argument("devices", nargs="*", help="default: every keyboard in /dev/input/by-id")
    args = parser.parse_args()

    paths = args.devices or sorted(glob.glob("/dev/input/by-id/*-event-kbd"))
    if not paths:
        sys.exit("no keyboards found")

    selector = selectors.DefaultSelector()
    for path in paths:
        selector.register(os.open(path, os.O_RDONLY), selectors.EVENT_READ, path)
        print(f"watching {path}")
    print(f"logging presses under {args.threshold:g} ms to {args.log}, totals in {args.totals}")

    signal.signal(signal.SIGTERM, lambda *_: sys.exit())
    presses, doubles = load_totals(args.totals)
    pressed, released = {}, {}
    next_save = time.monotonic() + SAVE_EVERY
    try:
        with args.log.open("a", buffering=1) as log:
            while True:
                for ready, _ in selector.select(SAVE_EVERY):
                    try:
                        data = os.read(ready.fd, EVENT.size * 64)
                    except OSError:
                        data = b""
                    if not data:
                        sys.exit(f"lost {ready.data}")

                    for sec, usec, kind, code, value in EVENT.iter_unpack(data):
                        if kind != EV_KEY or value not in (PRESS, RELEASE):
                            continue
                        now = sec * 1000 + usec / 1000
                        key = (ready.fd, code)
                        if value == RELEASE:
                            released[key] = now
                            continue
                        name = NAMES.get(code, f"CODE{code}")
                        last = pressed.get(key)
                        pressed[key] = now
                        if last is None or now - last > args.threshold:
                            presses[name] += 1
                            continue
                        doubles[name] += 1
                        gap = now - released.get(key, last)
                        stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                        line = (
                            f"{stamp}  {name:<12} {now - last:6.1f} ms apart, up for {gap:.1f} ms"
                        )
                        print(line)
                        log.write(line + "\n")

                if time.monotonic() >= next_save:
                    save_totals(args.totals, presses, doubles)
                    next_save = time.monotonic() + SAVE_EVERY
    finally:
        save_totals(args.totals, presses, doubles)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
