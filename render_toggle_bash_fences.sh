#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

[[ -f "_quarto.yml" ]] || { echo "Error: _quarto.yml not found in $SCRIPT_DIR" >&2; exit 1; }

mapfile -t CHAPTERS < <(printf '%s\n' *.qmd)
(( ${#CHAPTERS[@]} )) || { echo "Error: no .qmd files found in $SCRIPT_DIR" >&2; exit 1; }

DOCS_DIR="docs"
BACKUP_DIR="$(mktemp -d)"
mkdir -p "$DOCS_DIR"

restore() {
  for f in "${CHAPTERS[@]}"; do
    [[ -f "$BACKUP_DIR/$(basename "$f")" ]] && cp "$BACKUP_DIR/$(basename "$f")" "$f"
  done
  rm -rf "$BACKUP_DIR"
}
trap restore EXIT

# Back up originals, then strip {bash} → bash in place
for f in "${CHAPTERS[@]}"; do
  cp "$f" "$BACKUP_DIR/$(basename "$f")"
  sed -E -i 's/^```[[:space:]]*\{bash\}[[:space:]]*$/```bash/' "$f"
done

# Copy modified files to docs/
cp "${CHAPTERS[@]}" "$DOCS_DIR/"

quarto render "$@"

# restore() runs on EXIT and puts originals back
trap - EXIT
restore

# Overwrite files in docs/
cp "${CHAPTERS[@]}" "$DOCS_DIR/"

echo "Render complete. Bash fences restored to \`\`\`{bash}."
