#!/usr/bin/env bash
set -euo pipefail

# Run both outputs:
# 1) Book website (with temporary bash-fence conversion)
# 2) RevealJS HTML presentation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

./render_toggle_bash_fences.sh "$@"

# Render presentation from docs so presentation.html and presentation_files live together.
pushd docs >/dev/null
quarto render ../presentation.qmd --output presentation.html
popd >/dev/null

# Fallback for environments that still render artifacts in project root.
if [[ -f presentation.html ]]; then
	mv -f presentation.html docs/presentation.html
fi

if [[ -d presentation_files ]]; then
	rm -rf docs/presentation_files
	mv presentation_files docs/presentation_files
fi

echo "Done: book website + HTML presentation rendered."
