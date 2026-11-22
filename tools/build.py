#!/usr/bin/env python3
"""
EakUI bundler.

Packs every module under src/ into a single file (dist/EakUI.lua) so it can
be loaded with loadstring(game:HttpGet(...))().

Each module is wrapped in a function that receives `import`, so inside
src/ files you write:

    local import = ...
    local Utility = import("Core/Utility")

Module names are paths relative to src/ without ".lua";
"Folder/init.lua" is imported as "Folder".

Usage:
    python tools/build.py            # build dist/EakUI.lua
    python tools/build.py --minify   # also strip comments / blank lines
"""

from __future__ import annotations

import argparse
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
DIST = ROOT / "dist"
OUTPUT = DIST / "EakUI.lua"
ENTRY = "init"

RUNTIME = """\
local __modules = {}
local __cache = {}

local function import(name)
\tlocal cached = __cache[name]
\tif cached ~= nil then
\t\treturn cached
\tend
\tlocal loader = __modules[name]
\tif not loader then
\t\terror("[EakUI] module not found: " .. tostring(name), 2)
\tend
\tlocal result = loader(import)
\tif result == nil then
\t\tresult = true
\tend
\t__cache[name] = result
\treturn result
end
"""


def module_name(path: Path) -> str:
    name = path.relative_to(SRC).with_suffix("").as_posix()
    if name.endswith("/init"):
        name = name[: -len("/init")]
    return name


def read_version() -> str:
    state = (SRC / "Core" / "State.lua").read_text(encoding="utf-8")
    match = re.search(r'Version\s*=\s*"([^"]+)"', state)
    return match.group(1) if match else "0.0.0"


def minify(source: str) -> str:
    # Conservative: drops block comments, full-line comments and blank lines.
    source = re.sub(r"--\[(=*)\[.*?\]\1\]", "", source, flags=re.S)
    lines = []
    for line in source.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("--"):
            continue
        lines.append(line.rstrip())
    return "\n".join(lines)


def collect_modules() -> list[tuple[str, str]]:
    files = sorted(SRC.rglob("*.lua"))
    if not files:
        sys.exit(f"No .lua files found in {SRC}")

    modules = []
    seen = set()
    for path in files:
        name = module_name(path)
        if name in seen:
            sys.exit(f"Duplicate module name: {name}")
        seen.add(name)
        modules.append((name, path.read_text(encoding="utf-8")))

    if ENTRY not in seen:
        sys.exit(f"Entry module src/{ENTRY}.lua is missing")
    return modules


def build(do_minify: bool) -> None:
    version = read_version()
    modules = collect_modules()
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    parts = [
        "--[[",
        f"\tEakUI v{version}",
        f"\tBuilt {stamp} from {len(modules)} modules — do not edit by hand.",
        "\tSource: src/  |  Build: python tools/build.py",
        "]]",
        "",
        RUNTIME,
    ]

    for name, source in modules:
        body = minify(source) if do_minify else source.rstrip()
        parts.append(f'__modules["{name}"] = function(...)')
        parts.append(body)
        parts.append("end")
        parts.append("")

    parts.append(f'return import("{ENTRY}")')
    parts.append("")

    DIST.mkdir(exist_ok=True)
    OUTPUT.write_text("\n".join(parts), encoding="utf-8", newline="\n")

    size_kb = OUTPUT.stat().st_size / 1024
    print(f"Built {OUTPUT.relative_to(ROOT)} (v{version}, {len(modules)} modules, {size_kb:.1f} KB)")


def main() -> None:
    parser = argparse.ArgumentParser(description="Bundle EakUI into dist/EakUI.lua")
    parser.add_argument("--minify", action="store_true", help="strip comments and blank lines")
    args = parser.parse_args()
    build(args.minify)


if __name__ == "__main__":
    main()
