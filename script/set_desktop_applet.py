"""
Set the `plugin` key of the desktop containments in a Plasma layout file
(`~/.config/plasma-org.kde.plasma.desktop-appletsrc`).

A containment is considered a desktop if its current `plugin` is one of the
two desktop applets; sections of panels, widgets and other applets are left
untouched. Containment ids are not known (or guessed) here — the file is
scanned, so the desktops of all activities are updated, including ones the
shell created for additional activities.

If the file does not exist yet it is left absent: the shell will create the
default layout on first start, and we do not want to pre-create a stub
layout that the shell would then load instead of the default one.
"""

import re
import sys

DESKTOP_PLUGINS = ("org.kde.plasma.folder", "org.kde.desktopcontainment")
CONTAINMENT_HEADER = re.compile(r"^\[Containments\]\[[^\]]+\]\s*$")
PLUGIN_LINE = re.compile(r"^plugin\s*=\s*(?P<value>.+?)\s*$")


def desktop_plugin_lines(lines):
    """Yield (index, current value) of `plugin` lines in desktop sections."""
    in_containment = False
    for i, line in enumerate(lines):
        if CONTAINMENT_HEADER.match(line):
            in_containment = True
        elif line.startswith("["):
            in_containment = False
        elif in_containment:
            m = PLUGIN_LINE.match(line)
            if m and m.group("value") in DESKTOP_PLUGINS:
                yield i, m.group("value")


def main() -> int:
    if len(sys.argv) != 3:
        raise SystemExit(f"Usage: {sys.argv[0]} <layout-file> <plugin>")

    path, target = sys.argv[1], sys.argv[2]
    try:
        with open(path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except FileNotFoundError:
        return 0

    changed = [
        (i, value) for i, value in desktop_plugin_lines(lines) if value != target
    ]
    for i, _ in changed:
        lines[i] = f"plugin={target}\n"

    if changed:
        with open(path, "w", encoding="utf-8") as f:
            f.writelines(lines)
        print(
            f"set desktop containment plugin to {target!r} in {path} ({len(changed)} section(s))"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
