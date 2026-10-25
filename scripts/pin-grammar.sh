#!/bin/sh
# Points [grammars.goose] in extension.toml at the last commit that changed
# tree-sitter-goose/, in the given repository (by default this checkout, as a
# file:// URL, for installing as a dev extension).
#
#   scripts/pin-grammar.sh                                   # local dev
#   scripts/pin-grammar.sh https://github.com/you/zed-goose  # publishing
#
# The commit must be reachable in that repository: push before publishing.
set -eu
cd "$(dirname "$0")/.."
repository=${1:-"file://$(pwd)"}
rev=$(git log -1 --format=%H -- tree-sitter-goose)
[ -n "$rev" ] || { echo "commit tree-sitter-goose/ first" >&2; exit 1; }
if ! git diff --quiet HEAD -- tree-sitter-goose; then
    echo "warning: tree-sitter-goose/ has uncommitted changes, which $rev lacks" >&2
fi
awk -v repo="$repository" -v rev="$rev" '
    /^\[/ { section = $0 }
    section == "[grammars.goose]" && /^repository *=/ { print "repository = \"" repo "\""; next }
    section == "[grammars.goose]" && /^rev *=/ { print "rev = \"" rev "\""; next }
    { print }
' extension.toml > extension.toml.tmp
mv extension.toml.tmp extension.toml
echo "grammar: $repository @ $rev"
