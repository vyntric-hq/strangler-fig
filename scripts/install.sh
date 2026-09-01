#!/usr/bin/env bash
#
# Install a strangler-fig template into a target repository.
#
#   ./scripts/install.sh <template> <target-repo-path> [--force]
#
# Copies the template's agent definitions into <target>/.claude/agents/,
# its CONVENTIONS.md to the target root, and the slice discovery prompt
# to <target>/docs/refactor/. Existing files are never overwritten unless
# --force is passed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$REPO_DIR/templates"

usage() {
  echo "Usage: $(basename "$0") <template> <target-repo-path> [--force]" >&2
  echo "" >&2
  echo "Available templates:" >&2
  for t in "$TEMPLATES_DIR"/*/; do
    echo "  $(basename "$t")" >&2
  done
  exit 1
}

[ $# -ge 2 ] || usage

TEMPLATE="$1"
TARGET="$2"
FORCE="${3:-}"

TEMPLATE_DIR="$TEMPLATES_DIR/$TEMPLATE"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Error: unknown template '$TEMPLATE'" >&2
  usage
fi

if [ ! -d "$TARGET" ]; then
  echo "Error: target '$TARGET' is not a directory" >&2
  exit 1
fi

if [ -n "$FORCE" ] && [ "$FORCE" != "--force" ]; then
  echo "Error: unrecognized option '$FORCE'" >&2
  usage
fi

copy_file() {
  local src="$1"
  local dest="$2"
  if [ -e "$dest" ] && [ "$FORCE" != "--force" ]; then
    echo "  skip  ${dest} (exists, use --force to overwrite)"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "  copy  ${dest}"
}

echo "Installing template '$TEMPLATE' into $TARGET"

for agent in "$TEMPLATE_DIR"/agents/*.md; do
  copy_file "$agent" "$TARGET/.claude/agents/$(basename "$agent")"
done

copy_file "$TEMPLATE_DIR/CONVENTIONS.md" "$TARGET/CONVENTIONS.md"
copy_file "$REPO_DIR/prompts/discover-slices.md" "$TARGET/docs/refactor/discover-slices.md"

echo ""
echo "Done. Next steps:"
echo "  1. Read and tailor CONVENTIONS.md to your project. This step is not optional."
echo "  2. Open Claude Code in $TARGET and paste docs/refactor/discover-slices.md"
echo "     to map your application into vertical slices."
echo "  3. Pick a small pilot slice and run the per-slice workflow from the README:"
echo "     https://github.com/vyntric-hq/strangler-fig#per-slice-workflow"
