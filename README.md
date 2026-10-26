# Custom Shared AI Agent Skills

Central hub to maintain, update, and track unified custom skills for Claude Code and Codex across Windows, Mac, and Linux environments.

## Local Machine Workstation Setup

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