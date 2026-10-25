#!/bin/sh
# Refreshes tree-sitter-goose/ from a Goose checkout's tree-sitter/ directory
# and regenerates the parser, which upstream does not check in. Needs Node.js
# and Python. Commit the result, then run scripts/pin-grammar.sh.
#
#   scripts/update-grammar.sh /path/to/goose
set -eu
goose=${1:?usage: scripts/update-grammar.sh /path/to/goose}
cd "$(dirname "$0")/.."
python3 "$goose/tree-sitter/build.py"
dest=tree-sitter-goose
rm -rf "$dest/src" "$dest/queries" "$dest/test"
mkdir -p "$dest/src"
cp "$goose/tree-sitter/grammar.js" "$goose/tree-sitter/tree-sitter.json" "$goose/tree-sitter/package.json" "$dest/"
cp "$goose/LICENSE" "$dest/LICENSE"
cp -r "$goose/tree-sitter/queries" "$goose/tree-sitter/test" "$dest/"
cp -r "$goose/tree-sitter/src/parser.c" "$goose/tree-sitter/src/scanner.c" \
    "$goose/tree-sitter/src/grammar.json" "$goose/tree-sitter/src/node-types.json" \
    "$goose/tree-sitter/src/tree_sitter" "$dest/src/"
echo "updated $dest from $goose ($(git -C "$goose" rev-parse --short HEAD 2>/dev/null || echo unknown))"
echo "check languages/goose/*.scm still match the grammar's node names"
