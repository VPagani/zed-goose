# Goose for Zed

[Goose](https://github.com/aardappel/goose) language support for the
[Zed](https://zed.dev) editor.

- **Syntax highlighting** with the upstream tree-sitter grammar.
- **Language server**: the compiler serves LSP itself (`goose lsp`), which
  gives diagnostics as you type, hover, go to definition, references, rename,
  document and workspace symbols, signature help, completion, inlay hints and
  semantic tokens.
- **Outline** (structs, fields, enums, variants, functions, externs, globals),
  bracket matching, auto-indent, comment toggling, and Vim text objects
  (`af`/`if`, `ac`/`ic`, `gc`).
- **Tasks**: `goose run`, `check`, `build`, and C generation for the current
  file, plus a run button beside `fn main`.
- **Snippets**, the same as the VS Code extension's.

## Requirements

The Goose compiler on `PATH` (build it from the
[Goose repository](https://github.com/aardappel/goose)), or its path in the
settings below. The server finds the standard library the way `goose check`
does: `GOOSE_STDLIB`, or the `stdlib/` directory near the executable.

## Settings

All optional, in Zed's `settings.json`:

```jsonc
{
  "lsp": {
    "goose": {
      "binary": {
        // Defaults to `goose` on PATH. Relative paths are relative to the
        // worktree root, and `~` is the home directory.
        "path": "~/goose/build/goose",
        // Defaults to ["lsp"].
        "arguments": ["lsp"],
        "env": { "GOOSE_STDLIB": "/path/to/goose/stdlib" }
      },
      "settings": {
        // Have imported modules checked as part of the program that imports
        // them, so their errors show in them. Relative to the worktree root.
        "entryFiles": ["main.goose"],
        // The standard library, where the default lookup does not find it.
        "stdlib": "~/goose/stdlib"
      }
    }
  }
}
```

The extension sends `settings` as the server's initialization options and
again through `workspace/didChangeConfiguration`, so changes apply without a
restart. Keys in `initialization_options`, if given, are sent too, under
those in `settings`.

Zed requests semantic tokens only when enabled. The server colors names by
what they resolve to (functions, types, fields, variants, parameters,
variables), on top of the tree-sitter highlighting:

```jsonc
{
  "languages": {
    "Goose": { "semantic_tokens": "combined" }
  }
}
```

## Tasks

`task: spawn` lists the Goose tasks for the current file. The `goose run` task
is also the run button beside a top-level `fn main`. They call `goose` from
`PATH`; to use another compiler or pass more arguments, copy them from
[`languages/goose/tasks.json`](languages/goose/tasks.json) into your own
`tasks.json`.

## Installing as a dev extension

You need [Rust via rustup](https://www.rust-lang.org/tools/install).

1. Clone this repository and run `scripts/pin-grammar.sh`, which points the
   grammar at the local checkout (`file://…`). Zed fetches grammars with git,
   so the grammar must be committed.
2. In Zed, run `zed: install dev extension` and pick this directory.

`zed: open log` shows build errors; `zed --foreground` shows more.

## Layout

| Path | |
|---|---|
| `extension.toml` | The manifest: grammar, language server, snippets. |
| `src/goose.rs` | Starts `goose lsp` and passes it its options. |
| `languages/goose/` | Language config, tree-sitter queries, tasks. |
| `tree-sitter-goose/` | The upstream grammar (`tree-sitter/` in aardappel/goose) with the generated parser, which upstream does not check in and Zed needs. |
| `snippets/goose.json` | Snippets. |
| `scripts/update-grammar.sh` | Refreshes `tree-sitter-goose/` from a Goose checkout. |
| `scripts/pin-grammar.sh` | Points `extension.toml` at the committed grammar. |

## Updating the grammar

```sh
scripts/update-grammar.sh /path/to/goose
git add tree-sitter-goose && git commit -m "Update the grammar"
scripts/pin-grammar.sh https://github.com/VPagani/zed-goose
git commit -am "Pin the grammar"
```

`languages/goose/highlights.scm` is adapted from the upstream
`queries/highlights.scm` with Zed's capture names, so check it, and the other
queries, against grammar changes: `tree-sitter query languages/goose/<file>.scm
some.goose`, run in `tree-sitter-goose/`, fails on a node the grammar no longer
has.

## Publishing

Push this repository to GitHub, then run
`scripts/pin-grammar.sh https://github.com/VPagani/zed-goose`, set `repository` at
the top of `extension.toml` to the same URL, commit, push, and open a pull
request against [zed-industries/extensions](https://github.com/zed-industries/extensions)
as its [publishing guide](https://zed.dev/docs/extensions/developing-extensions#publishing-your-extension)
describes.

## License

Apache-2.0, as Goose is. The grammar in `tree-sitter-goose/` is from the Goose
repository.
