#!/bin/bash
set -e

# Find the absolute location of this repository's skills directory
REPO_SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE}")/../skills" && pwd)"

CLAUDE_TARGET="$HOME/.claude/skills"
CODEX_TARGET="$HOME/.codex/skills"

echo "Initializing systemic skill target locations..."
mkdir -p "$CLAUDE_TARGET"
mkdir -p "$CODEX_TARGET"

echo "Mapping active capabilities to agent platforms..."
# Dynamically iterates through both custom internal and external community folders
for skill_folder in "$REPO_SKILLS_DIR"/*; do
    if [ -d "$skill_folder" ]; then
        SKILL_NAME=$(basename "$skill_folder")
        
        # Strip legacy target maps to avoid caching collision issues
        rm -rf "$CLAUDE_TARGET/$SKILL_NAME"
        rm -rf "$CODEX_TARGET/$SKILL_NAME"

        # Dynamically link the folders to both AI platforms
        ln -sf "$skill_folder" "$CLAUDE_TARGET/$SKILL_NAME"
        ln -sf "$skill_folder" "$CODEX_TARGET/$SKILL_NAME"
        echo " ✓ Skill Registered: $SKILL_NAME"
    fi
done
echo "Ecosystem Sync Complete!"