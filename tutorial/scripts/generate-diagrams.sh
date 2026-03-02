#!/usr/bin/env bash
# Generate SVG diagrams from DOT files using Graphviz.
# Usage: bash scripts/generate-diagrams.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIAGRAMS_DIR="$SCRIPT_DIR/../diagrams"
OUTPUT_DIR="$SCRIPT_DIR/../public/diagrams"

mkdir -p "$OUTPUT_DIR"

count=0
for dot_file in "$DIAGRAMS_DIR"/*.dot; do
  [ -f "$dot_file" ] || continue
  name="$(basename "$dot_file" .dot)"
  echo "Generating $name.svg..."
  dot -Tsvg "$dot_file" -o "$OUTPUT_DIR/$name.svg"
  count=$((count + 1))
done

echo "Generated $count diagram(s) in $OUTPUT_DIR"
