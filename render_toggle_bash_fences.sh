#!/usr/bin/env bash
set -euo pipefail

# Run from the repository root (directory containing this script).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ ! -f "_quarto.yml" ]]; then
  echo "Error: _quarto.yml not found in $SCRIPT_DIR" >&2
  exit 1
fi

mapfile -t CHAPTERS < <(
  awk '
    /^[[:space:]]*chapters:[[:space:]]*$/ { in_chapters=1; next }
    in_chapters && /^[[:space:]]*-[[:space:]]+.*\.qmd[[:space:]]*$/ {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]+/, "", line)
      gsub(/[[:space:]]+$/, "", line)
      print line
      next
    }
    in_chapters && !/^[[:space:]]*-/ { in_chapters=0 }
  ' _quarto.yml
)

if [[ ${#CHAPTERS[@]} -eq 0 ]]; then
  echo "Error: no chapter .qmd files found under 'chapters:' in _quarto.yml" >&2
  exit 1
fi

restore_fences() {
  for file in "${CHAPTERS[@]}"; do
    [[ -f "$file" ]] || continue
    sed -E -i 's/^([[:space:]]*)```[[:space:]]*bash[[:space:]]*$/\1```{bash}/' "$file"
  done
}

# Always restore fences, even if quarto render fails or script is interrupted.
trap restore_fences EXIT

for file in "${CHAPTERS[@]}"; do
  [[ -f "$file" ]] || continue
  sed -E -i 's/^([[:space:]]*)```[[:space:]]*\{bash\}[[:space:]]*$/\1```bash/' "$file"
done

quarto render "$@"

# Restore now and disable the EXIT trap to avoid running twice.
restore_fences
trap - EXIT

echo "Render complete. Bash fences were restored to \`\`\`{bash}."
