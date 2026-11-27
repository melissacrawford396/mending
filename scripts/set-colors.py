#!/usr/bin/env python3
"""Sets the Unity figure's default colors and light from a pasted block.

The block is what "Copy all" in the Colors menu copies:

    Skin: new Color(1f, 1f, 1f)
    Joints: new Color(0.6f, 0.8f, 0.98f)
    Ground: new Color(0.48f, 0.54f, 0.58f, 0.92f)
    Background: new Color(0.19f, 0.19f, 0.19f)
    Main light: 1.3f
    Fill light: new Color(0.92f, 0.95f, 1f)

    scripts/set-colors.py              reads the block from the clipboard
    pbpaste | scripts/set-colors.py    or from stdin

Any subset of lines works. Ground keeps its current alpha if none is given.
"""
import re
import subprocess
import sys
from pathlib import Path

FIGURE = Path(__file__).resolve().parent.parent / "unity/Mending/Assets/Scripts/Figure"
COLOR = r"new Color\([^)]*\)"

# name -> (file, pattern whose group 1 is kept and group 2 is replaced)
TARGETS = {
    "Skin": ("CuteFigure.cs", r"(limbMaterial = MakeMaterial\()(" + COLOR + r")"),
    "Joints": ("CuteFigure.cs", r"(jointMaterial = MakeMaterial\()(" + COLOR + r")"),
    "Ground": ("FigureStage.cs", r"(var color = )(" + COLOR + r")(?=;\s*if \(material\.HasProperty\(\"_BaseColor\"\)\))"),
    "Background": ("FigureStage.cs", r"(cam\.backgroundColor = )(" + COLOR + r")"),
    "Main light": ("FigureStage.cs", r"(sceneLight\.intensity = )([0-9.]+f)"),
    "Fill light": ("FigureStage.cs", r"(RenderSettings\.ambientLight = )(" + COLOR + r")"),
}


def fail(message):
    sys.exit("set-colors: " + message)


def number(text):
    try:
        return float(text.strip().rstrip("fF"))
    except ValueError:
        fail("not a number: " + text.strip())


def code_number(value):
    text = ("%.4f" % value).rstrip("0").rstrip(".")
    return (text or "0") + "f"


def parse_color(name, text):
    match = re.fullmatch(r"new Color\(([^)]*)\)", text)
    if not match:
        fail(name + " should look like new Color(0.5f, 0.5f, 0.5f), got: " + text)
    values = [number(part) for part in match.group(1).split(",")]
    if len(values) not in (3, 4):
        fail(name + " needs 3 or 4 numbers, got: " + text)
    if any(v < 0 or v > 1 for v in values):
        fail(name + " numbers must be between 0 and 1, got: " + text)
    return values


def color_code(values):
    return "new Color(" + ", ".join(code_number(v) for v in values) + ")"


def read_block():
    if not sys.stdin.isatty():
        return sys.stdin.read()
    try:
        return subprocess.run(["pbpaste"], capture_output=True, text=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError):
        fail("pipe the block in, for example: pbpaste | scripts/set-colors.py")


def parse(block):
    picks = {}
    for line in block.splitlines():
        line = line.strip()
        if not line:
            continue
        match = re.fullmatch(r"([A-Za-z ]+?)\s*:\s*(.+)", line)
        if not match or match.group(1) not in TARGETS:
            fail("unknown line: " + line + "\nExpected: " + ", ".join(TARGETS))
        name, value = match.group(1), match.group(2).rstrip(";").strip()
        if name == "Main light":
            amount = number(value)
            if amount < 0:
                fail("Main light must be 0 or more, got: " + value)
            picks[name] = amount
        else:
            picks[name] = parse_color(name, value)
    if not picks:
        fail("nothing to set. Copy the block from Copy all in the Colors menu first.")
    return picks


def main():
    picks = parse(read_block())
    sources = {}
    for name, value in picks.items():
        filename, pattern = TARGETS[name]
        path = FIGURE / filename
        text = sources.get(path)
        if text is None:
            text = path.read_text()
        found = list(re.finditer(pattern, text))
        if len(found) != 1:
            fail("found %d places for %s in %s, expected 1" % (len(found), name, filename))
        old = found[0].group(2)

        if name == "Main light":
            new = code_number(value)
        else:
            if name == "Ground" and len(value) == 3:
                alpha = parse_color(name, old)
                if len(alpha) == 4:
                    value = value + [alpha[3]]
            new = color_code(value)

        start, end = found[0].span(2)
        sources[path] = text[:start] + new + text[end:]
        print("%-11s %s" % (name + ":", new) + ("" if new != old else "   (unchanged)"))

    for path, text in sources.items():
        path.write_text(text)
    print("Updated. Stop Play and press Play again to see it.")


if __name__ == "__main__":
    main()
