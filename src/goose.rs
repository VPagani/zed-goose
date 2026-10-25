use std::collections::HashMap;

use zed_extension_api::{
    self as zed,
    serde_json::{self, Map, Value},
    settings::LspSettings,
    LanguageServerId, Result, Worktree,
};

/// The id of the language server in `extension.toml`, which is also the key
/// of its settings under `lsp` in Zed's settings.
const SERVER_ID: &str = "goose";

/// Options the server reads (`Workspace::Configure` in the compiler's
/// `src/lsp_workspace.h`) that name files, and so are resolved against the
/// worktree when relative.
const PATH_OPTIONS: &[&str] = &["stdlib"];
const PATH_LIST_OPTIONS: &[&str] = &["entryFiles"];

struct GooseExtension;

impl GooseExtension {
    /// The `goose` executable: `lsp.goose.binary.path` when set, else the
    /// first `goose` on the worktree's PATH.
    fn compiler_path(&self, settings: &LspSettings, worktree: &Worktree) -> Result<String> {
        if let Some(path) = settings.binary.as_ref().and_then(|b| b.path.clone()) {
            return Ok(resolve(&path, worktree));
        }
        worktree.which("goose").ok_or_else(|| {
            "The Goose compiler (goose) is not on PATH. Build it from \
             https://github.com/aardappel/goose and put it on PATH, or set \
             lsp.goose.binary.path in Zed's settings to its full path."
                .to_string()
        })
    }

    /// The server's options: `lsp.goose.initialization_options` with
    /// `lsp.goose.settings` over it, and relative paths made absolute, as the
    /// server wants them.
    fn options(&self, worktree: &Worktree) -> Result<Value> {
        let settings = LspSettings::for_worktree(SERVER_ID, worktree)?;
        let mut options = Map::new();
        for source in [settings.initialization_options, settings.settings] {
            if let Some(Value::Object(map)) = source {
                options.extend(map);
            }
        }
        for key in PATH_OPTIONS {
            if let Some(Value::String(path)) = options.get_mut(*key) {
                *path = resolve(path, worktree);
            }
        }
        for key in PATH_LIST_OPTIONS {
            if let Some(Value::Array(paths)) = options.get_mut(*key) {
                for path in paths.iter_mut() {
                    if let Value::String(path) = path {
                        *path = resolve(path, worktree);
                    }
                }
            }
        }
        Ok(Value::Object(options))
    }
}

impl zed::Extension for GooseExtension {
    fn new() -> Self {
        GooseExtension
    }

    fn language_server_command(
        &mut self,
        _language_server_id: &LanguageServerId,
        worktree: &Worktree,
    ) -> Result<zed::Command> {
        let settings = LspSettings::for_worktree(SERVER_ID, worktree)?;
        let command = self.compiler_path(&settings, worktree)?;
        let (args, extra_env) = match settings.binary {
            Some(binary) => (binary.arguments, binary.env),
            None => (None, None),
        };
        let args = args.unwrap_or_else(|| vec!["lsp".to_string()]);
        let mut env: HashMap<String, String> = worktree.shell_env().into_iter().collect();
        env.extend(extra_env.unwrap_or_default());
        Ok(zed::Command {
            command,
            args,
            env: env.into_iter().collect(),
        })
    }

    fn language_server_initialization_options(
        &mut self,
        _language_server_id: &LanguageServerId,
        worktree: &Worktree,
    ) -> Result<Option<Value>> {
        self.options(worktree).map(Some)
    }

    // The server takes the same options again from
    // workspace/didChangeConfiguration, under `goose`, so that a change to
    // them applies without a restart.
    fn language_server_workspace_configuration(
        &mut self,
        _language_server_id: &LanguageServerId,
        worktree: &Worktree,
    ) -> Result<Option<Value>> {
        Ok(Some(serde_json::json!({ "goose": self.options(worktree)? })))
    }
}

/// `path` against the worktree root, with a leading `~` for the home
/// directory, which neither Zed nor the server expands.
fn resolve(path: &str, worktree: &Worktree) -> String {
    let home = worktree
        .shell_env()
        .into_iter()
        .find(|(name, _)| name == "HOME" || name == "USERPROFILE")
        .map(|(_, value)| value);
    join(path, &worktree.root_path(), home.as_deref())
}

/// `path` against `root`, unless it is absolute already (a Unix path, a
/// Windows drive or UNC path).
fn join(path: &str, root: &str, home: Option<&str>) -> String {
    if let (Some(rest), Some(home)) = (path.strip_prefix('~'), home) {
        if rest.is_empty() {
            return home.to_string();
        }
        if rest.starts_with(['/', '\\']) {
            return join(rest.trim_start_matches(['/', '\\']), home, None);
        }
    }
    let bytes = path.as_bytes();
    let absolute = path.starts_with(['/', '\\'])
        || (bytes.len() >= 2 && bytes[0].is_ascii_alphabetic() && bytes[1] == b':');
    if absolute || path.is_empty() {
        return path.to_string();
    }
    let path = path.strip_prefix("./").unwrap_or(path);
    let separator = if root.contains('\\') && !root.contains('/') { '\\' } else { '/' };
    format!("{}{separator}{path}", root.trim_end_matches(['/', '\\']))
}

zed::register_extension!(GooseExtension);

#[cfg(test)]
mod tests {
    use super::join;

    #[test]
    fn resolves_relative_paths_against_the_root() {
        assert_eq!(join("main.goose", "/p", None), "/p/main.goose");
        assert_eq!(join("./src/main.goose", "/p/", None), "/p/src/main.goose");
        assert_eq!(join("main.goose", r"C:\p", None), r"C:\p\main.goose");
    }

    #[test]
    fn expands_the_home_directory() {
        assert_eq!(join("~/goose/stdlib", "/p", Some("/home/u")), "/home/u/goose/stdlib");
        assert_eq!(join("~", "/p", Some("/home/u")), "/home/u");
        assert_eq!(join("~x", "/p", Some("/home/u")), "/p/~x");
        assert_eq!(join("~/goose", "/p", None), "/p/~/goose");
    }

    #[test]
    fn keeps_absolute_paths() {
        assert_eq!(join("/x/main.goose", "/p", None), "/x/main.goose");
        assert_eq!(join(r"D:\x\main.goose", "/p", None), r"D:\x\main.goose");
        assert_eq!(join(r"\\server\share", "/p", None), r"\\server\share");
    }
}
