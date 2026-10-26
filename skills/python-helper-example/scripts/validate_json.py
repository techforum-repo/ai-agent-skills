#!/usr/bin/env python3
"""Read-only JSON validation helper used by the example skill."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: validate_json.py <path-to-json>", file=sys.stderr)
        return 2

    input_path = Path(sys.argv[1])
    try:
        with input_path.open(encoding="utf-8") as json_file:
            value = json.load(json_file)
    except FileNotFoundError:
        print(f"JSON file not found: {input_path}", file=sys.stderr)
        return 1
    except json.JSONDecodeError as error:
        print(f"Invalid JSON in {input_path}: {error}", file=sys.stderr)
        return 1

    print(f"Valid JSON: {input_path} (top-level {type(value).__name__})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
