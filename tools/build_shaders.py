#!/usr/bin/env python3
"""Compile the Meniscus shaders to .qsb next to their sources.

Uses the first qsb it finds: $QSB, qsb-qt6, qsb, Qt's libexec copies, or the
one bundled with PySide6. KWin renders with OpenGL / OpenGL ES, so only the
GLSL variants are baked.
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENTS = ROOT / "package" / "effects" / "meniscus" / "contents"
SHADER_DIRS = [CONTENTS / "shaders", CONTENTS / "ui" / "LiquidGlass" / "shaders"]
# The scene graph picks the newest variant the context supports.
GLSL_TARGETS = "100 es,120,150,300 es,330"


def find_qsb() -> str | None:
    candidates = [os.environ.get("QSB"), "qsb-qt6", "qsb", "qsb6",
                  "/usr/lib64/qt6/bin/qsb", "/usr/lib/qt6/bin/qsb",
                  "/usr/lib/x86_64-linux-gnu/qt6/bin/qsb"]
    for candidate in candidates:
        if candidate and shutil.which(candidate):
            return shutil.which(candidate)
    try:
        import PySide6
    except ImportError:
        return None
    for name in ("qsb.exe", "qsb", "Qt/libexec/qsb"):
        bundled = Path(PySide6.__file__).parent / name
        if bundled.is_file():
            return str(bundled)
    return None


def main() -> int:
    qsb = find_qsb()
    if qsb is None:
        print("qsb not found: install qt6-qtshadertools (qsb-qt6) or PySide6", file=sys.stderr)
        return 1
    failed = 0
    for directory in SHADER_DIRS:
        for source in sorted(directory.glob("*.frag")) + sorted(directory.glob("*.vert")):
            target = source.with_name(source.name + ".qsb")
            result = subprocess.run([qsb, "--glsl", GLSL_TARGETS, "-o", str(target), str(source)],
                                    capture_output=True, text=True)
            if result.returncode != 0:
                failed += 1
                print(f"FAILED {source.name}\n{result.stdout}{result.stderr}", file=sys.stderr)
            else:
                print(f"{source.name} -> {target.name} ({target.stat().st_size} bytes)")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
