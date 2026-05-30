#!/usr/bin/env bash
# install.sh — copy agents and skills into ~/.claude/
# Run: bash install.sh

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_AGENTS="$HOME/.claude/agents"
TARGET_SKILLS="$HOME/.claude/skills"

echo "Installing Claude agents and skills from $REPO_DIR"

mkdir -p "$TARGET_AGENTS" "$TARGET_SKILLS"

# Copy agents
for file in "$REPO_DIR"/agents/*.md; do
  name="$(basename "$file")"
  if [ -f "$TARGET_AGENTS/$name" ]; then
    echo "  [update] agents/$name"
  else
    echo "  [new]    agents/$name"
  fi
  cp "$file" "$TARGET_AGENTS/$name"
done

# Copy skills (each skill is a directory containing SKILL.md)
for skill_dir in "$REPO_DIR"/skills/*/; do
  name="$(basename "$skill_dir")"
  mkdir -p "$TARGET_SKILLS/$name"
  if [ -f "$TARGET_SKILLS/$name/SKILL.md" ]; then
    echo "  [update] skills/$name/SKILL.md"
  else
    echo "  [new]    skills/$name/SKILL.md"
  fi
  cp "$skill_dir/SKILL.md" "$TARGET_SKILLS/$name/SKILL.md"
done

echo ""
echo "Done. Restart Claude Code to pick up new agents and skills."
