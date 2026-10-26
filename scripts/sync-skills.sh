#!/bin/bash
# Automatically finds the repository root directory
REPO_SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../skills" && pwd)"

CLAUDE_TARGET="$HOME/.claude/skills"
CODEX_TARGET="$HOME/.codex/skills"

echo "Creating base target directories..."
mkdir -p "$CLAUDE_TARGET"
mkdir -p "$CODEX_TARGET"

echo "Symlinking skills to global AI agent environments..."
for skill in "$REPO_SKILLS_DIR"/*; do
    if [ -d "$skill" ]; then
        SKILL_NAME=$(basename "$skill")
        
        # Force remove existing link or old files
        rm -rf "$CLAUDE_TARGET/$SKILL_NAME"
        rm -rf "$CODEX_TARGET/$SKILL_NAME"

        # Create dynamic soft links
        ln -sf "$skill" "$CLAUDE_TARGET/$SKILL_NAME"
        ln -sf "$skill" "$CODEX_TARGET/$SKILL_NAME"
        echo " ✓ Linked: $SKILL_NAME"
    fi
done
echo "Sync complete!"