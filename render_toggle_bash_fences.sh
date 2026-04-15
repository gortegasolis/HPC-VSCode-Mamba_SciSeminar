#!/usr/bin/env bash
set -euo pipefail

# Run from the repository root (directory containing this script).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ ! -f "_quarto.yml" ]]; then
  echo "Error: _quarto.yml not found in $SCRIPT_DIR" >&2
  exit 1
fi

# All .qmd files directly in the root folder.
mapfile -t CHAPTERS < <(printf '%s\n' *.qmd)

if [[ ${#CHAPTERS[@]} -eq 0 ]]; then
  echo "Error: no .qmd files found in $SCRIPT_DIR" >&2
  exit 1
fi

BACKUP_DIR="docs/site_libs"
mkdir -p "$BACKUP_DIR"

restore_from_backups() {
  for file in "${CHAPTERS[@]}"; do
    backup="$BACKUP_DIR/$(basename "$file")"
    [[ -f "$backup" ]] || continue
    cp "$backup" "$file"
    rm "$backup"
  done
}

# Restore any backups left over from a previously interrupted run
# so fences are always in the correct ```{bash} state before we start.
restore_from_backups

# Copy originals to backup dir before modifying them.
for file in "${CHAPTERS[@]}"; do
  [[ -f "$file" ]] || continue
  cp "$file" "$BACKUP_DIR/$(basename "$file")"
done

# Always restore from backups, even if quarto render fails or script is interrupted.
trap restore_from_backups EXIT

# Replace ```{bash} with ```{bash} in the originals.
for file in "${CHAPTERS[@]}"; do
  [[ -f "$file" ]] || continue
  sed -E -i 's/^([[:space:]]*)```[[:space:]]*\{bash\}[[:space:]]*$/\1```{bash}/' "$file"
done

quarto render "$@"

# Restore from backups and disable the EXIT trap to avoid running twice.
restore_from_backups
trap - EXIT

echo "Render complete. Bash fences were restored to \`\`\`{bash}."
