#!/bin/bash
set -e

# Establish repository root absolute reference path
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd)"
REPO_SKILLS_DIR="$REPO_ROOT/skills"
MANIFEST_FILE="$REPO_ROOT/config/external-skills.json"

CLAUDE_TARGET="$HOME/.claude/skills"
CODEX_TARGET="$HOME/.codex/skills"

# Step 1: Process and clone/update declarative external skills
if [ -f "$MANIFEST_FILE" ]; then
    echo "Processing external skills manifest..."
    
    # Extract entries using basic text parsing to remove heavy external tooling requirements
    grep -o '"repo": "[^"]*"' "$MANIFEST_FILE" | cut -d'"' -f4 | while read -r repo; do
        # Extract the metadata values matching the repository mapping keys
        name=$(grep -B 1 "\"repo\": \"$repo\"" "$MANIFEST_FILE" | grep '"name":' | cut -d'"' -f4)
        ref=$(grep -A 1 "\"repo\": \"$repo\"" "$MANIFEST_FILE" | grep '"ref":' | cut -d'"' -f4)
        
        TARGET_DIR="$REPO_SKILLS_DIR/$name"
        
        echo " 📥 Fetching external skill: $name ($repo#$ref)..."
        # Only replace skill folders managed by this repository. A marker makes
        # ownership explicit and prevents an accidental deletion of local work.
        if [ -e "$TARGET_DIR" ] && [ ! -f "$TARGET_DIR/.ai-agent-skills-managed" ]; then
            echo "Skipping $name: $TARGET_DIR exists and is not managed by this repository."
            continue
        fi
        rm -rf "$TARGET_DIR"
        npx --yes degit "$repo#$ref" "$TARGET_DIR" --force
        touch "$TARGET_DIR/.ai-agent-skills-managed"
    done
fi

# Step 2: Systemic link routing mappings
echo "Initializing systemic skill target locations..."
mkdir -p "$CLAUDE_TARGET"
mkdir -p "$CODEX_TARGET"

echo "Mapping active capabilities to agent platforms..."
for skill_folder in "$REPO_SKILLS_DIR"/*; do
    if [ -d "$skill_folder" ]; then
        SKILL_NAME=$(basename "$skill_folder")
        
        for target in "$CLAUDE_TARGET/$SKILL_NAME" "$CODEX_TARGET/$SKILL_NAME"; do
            if [ -e "$target" ] && [ ! -L "$target" ]; then
                echo "Skipping $target: it is not a symlink managed by this installer."
                continue 2
            fi
        done

        rm -f "$CLAUDE_TARGET/$SKILL_NAME"
        rm -f "$CODEX_TARGET/$SKILL_NAME"

        ln -sf "$skill_folder" "$CLAUDE_TARGET/$SKILL_NAME"
        ln -sf "$skill_folder" "$CODEX_TARGET/$SKILL_NAME"
        echo " ✓ Skill Registered Natively: $SKILL_NAME"
    fi
done
echo "Ecosystem Sync Complete!"
