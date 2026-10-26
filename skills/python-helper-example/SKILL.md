---
name: python-helper-example
description: Example of packaging a small deterministic Python helper with a portable agent skill. Use as a template when a skill needs repeatable local validation or transformation.
---

# Python Helper Example

Use this skill as a reference when a reusable skill needs a deterministic local script. Keep the helper scoped to one concrete task, accept explicit input paths, and print a concise result suitable for an agent to inspect.

`scripts/validate_json.py` validates a JSON file and reports its top-level type. It is intentionally read-only.

Run it only when JSON validation is part of the requested task:

```bash
python3 scripts/validate_json.py path/to/file.json
```

For a real skill, replace this validator with the repeated operation that benefits from deterministic execution. Document inputs, output, dependencies, and any mutation or authorization requirements here.
