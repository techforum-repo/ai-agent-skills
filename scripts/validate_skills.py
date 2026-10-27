#!/usr/bin/env python3
"""Validate SKILL.md frontmatter for every skill in skills/ (standard library only)."""

from __future__ import annotations

import re
import sys
from pathlib import Path

NAME_PATTERN = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
MAX_NAME_LENGTH = 64
MAX_DESCRIPTION_LENGTH = 1024
# Keys that look right but are silently ignored by the agents.
MISSPELLED_KEYS = {"allowed_tools": "allowed-tools", "allowedTools": "allowed-tools"}


def parse_frontmatter(text: str) -> dict[str, str] | None:
    """Return top-level scalar keys of the YAML frontmatter, or None when it is missing."""
    match = re.match(r"^---\r?\n(.*?)\r?\n---\r?\n", text, re.DOTALL)
    if not match:
        return None
    fields: dict[str, str] = {}
    for line in match.group(1).splitlines():
        key_match = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", line)
        if key_match:
            fields[key_match.group(1)] = key_match.group(2).strip().strip("\"'")
    return fields


def validate(skill_dir: Path) -> list[str]:
    skill_file = skill_dir / "SKILL.md"
    if not skill_file.is_file():
        return ["missing SKILL.md"]
    fields = parse_frontmatter(skill_file.read_text(encoding="utf-8"))
    if fields is None:
        return ["SKILL.md has no YAML frontmatter"]

    errors = []
    name = fields.get("name", "")
    if not name:
        errors.append("frontmatter is missing 'name'")
    elif not NAME_PATTERN.match(name) or len(name) > MAX_NAME_LENGTH:
        errors.append(f"name '{name}' must be lowercase letters, digits and hyphens (max {MAX_NAME_LENGTH})")
    elif name != skill_dir.name:
        errors.append(f"name '{name}' does not match folder name '{skill_dir.name}'")

    description = fields.get("description", "")
    if not description:
        errors.append("frontmatter is missing 'description'")
    elif len(description) > MAX_DESCRIPTION_LENGTH:
        errors.append(f"description is {len(description)} characters (max {MAX_DESCRIPTION_LENGTH})")

    for wrong, right in MISSPELLED_KEYS.items():
        if wrong in fields:
            errors.append(f"'{wrong}' is ignored; use '{right}'")
    return errors


def main() -> int:
    skills_root = Path(__file__).resolve().parent.parent / "skills"
    failed = False
    for skill_dir in sorted(p for p in skills_root.iterdir() if p.is_dir()):
        # External skills are validated upstream and are not committed here.
        if skill_dir.name.startswith("ext-"):
            continue
        errors = validate(skill_dir)
        if errors:
            failed = True
            for error in errors:
                print(f"{skill_dir.name}: {error}")
        else:
            print(f"{skill_dir.name}: ok")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
