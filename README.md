# Custom Shared AI Agent Skills

Central hub to maintain, update, and track unified custom skills for Claude Code and Codex across Windows, Mac, and Linux environments.

## Local Machine Workstation Setup

The sync scripts register repository skills in Claude Code and Codex using symbolic links. They only replace links that they previously created; an existing directory is treated as user-owned and is left untouched.

### For macOS, Linux, and Windows WSL
Make the setup script executable and run it:
```bash
chmod +x scripts/sync-skills.sh
./scripts/sync-skills.sh
```

### For Native Windows (PowerShell Host)
Open PowerShell as an Administrator and execute:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\scripts\sync-skills.ps1
```

## Adding New Skills
1. Create a new folder inside `skills/` (e.g., `skills/my-new-skill/`).
2. Add a `SKILL.md` inside it containing accurate YAML frontmatter configurations.
3. Rerun the synchronization script to instantly map it to your active CLI frameworks.

## External skills

`config/external-skills.json` pins each external source to a commit SHA for reproducible installs. Update a pin deliberately, review the upstream change, and rerun the sync script. Downloaded external skills contain an `.ai-agent-skills-managed` marker, allowing the installer to safely distinguish its own directories from user-created ones.

Claude plugins are not automatically registered as skills. Install them through Claude Code's plugin mechanism, because a plugin can contain commands, hooks, or other assets that the skill installer cannot safely map.

## Compatibility

Use the `SKILL.md` format for portable skills. Tool-specific configuration—such as Claude Code rules, hooks, commands, or GitHub Copilot instruction files—belongs in its owning tool repository rather than this shared skill hub.

`skills/python-helper-example/` demonstrates the preferred structure for a portable skill that includes a small Python helper. It is read-only and can be copied as a starting point when deterministic validation or transformation is warranted.
