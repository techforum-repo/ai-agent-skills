#!/bin/bash
set -euo pipefail

# Usage: ./scripts/sync-skills.sh [--dry-run]
DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=1
    echo "Dry run: no files will be changed."
fi

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "   would run: $*"
    else
        "$@"
    fi
}

# Establish repository root absolute reference path
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_SKILLS_DIR="$REPO_ROOT/skills"
MANIFEST_FILE="$REPO_ROOT/config/external-skills.json"

CLAUDE_TARGET="$HOME/.claude/skills"
CODEX_TARGET="$HOME/.codex/skills"

# Step 1: Process and clone/update declarative external skills
if [ -f "$MANIFEST_FILE" ]; then
    echo "Processing external skills manifest..."

    # Parse the manifest with Node (already required for degit) so key order and
    # formatting in the JSON file do not matter. Emits one "name<TAB>repo<TAB>ref" line per skill.
    node -e '
        const m = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
        for (const s of m.external_skills || []) {
            if (!s.name || !s.repo || !s.ref) throw new Error("Manifest entry needs name, repo and ref: " + JSON.stringify(s));
            console.log([s.name, s.repo, s.ref].join("\t"));
        }' "$MANIFEST_FILE" | while IFS=$'\t' read -r name repo ref; do
        TARGET_DIR="$REPO_SKILLS_DIR/$name"

        echo " Fetching external skill: $name ($repo#$ref)..."
        # Only replace skill folders managed by this repository. A marker makes
        # ownership explicit and prevents an accidental deletion of local work.
        if [ -e "$TARGET_DIR" ] && [ ! -f "$TARGET_DIR/.ai-agent-skills-managed" ]; then
            echo "Skipping $name: $TARGET_DIR exists and is not managed by this repository."
            continue
        fi
        run rm -rf "$TARGET_DIR"
        run npx --yes degit "$repo#$ref" "$TARGET_DIR" --force
        run touch "$TARGET_DIR/.ai-agent-skills-managed"
    done
fi

# Step 2: Systemic link routing mappings
echo "Initializing systemic skill target locations..."
run mkdir -p "$CLAUDE_TARGET" "$CODEX_TARGET"

# Remove links this installer created for skills that no longer exist in the repository.
echo "Pruning stale links..."
for target_dir in "$CLAUDE_TARGET" "$CODEX_TARGET"; do
    [ -d "$target_dir" ] || continue
    for link in "$target_dir"/*; do
        [ -L "$link" ] || continue
        case "$(readlink "$link")" in
            "$REPO_SKILLS_DIR"/*)
                if [ ! -e "$link" ]; then
                    run rm -f "$link"
                    echo " - Removed stale link: $link"
                fi
                ;;
        esac
    done
done

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

        run rm -f "$CLAUDE_TARGET/$SKILL_NAME" "$CODEX_TARGET/$SKILL_NAME"
        run ln -s "$skill_folder" "$CLAUDE_TARGET/$SKILL_NAME"
        run ln -s "$skill_folder" "$CODEX_TARGET/$SKILL_NAME"
        echo " ✓ Skill Registered Natively: $SKILL_NAME"
    fi
done
echo "Ecosystem Sync Complete!"
