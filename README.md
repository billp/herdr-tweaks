# herdr-tweaks

Tweaks for [herdr](https://herdr.dev) (0.9.5+) that name tabs, tiles and sidebar rows after the git branches you are working on.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/billp/herdr-tweaks/main/install.sh | bash
```

Needs `herdr`, `git`, `jq`. The installer clones to `~/Projects/herdr-tweaks` (override with `HERDR_TWEAKS_DIR`), is idempotent (re-run it to update), and:

1. symlinks `bin/herdr-branch-tags` into `~/.local/bin`
2. links the herdr plugin in `plugin/` (`local.branch-tags`)
3. adds `config/config.toml` to `~/.config/herdr/config.toml` between `# >>> herdr-tweaks >>>` markers and reloads herdr (if you already have `[ui]` / `[ui.sidebar.*]` sections it prints the block for you to merge instead)
4. adds a `source …/zsh/herdr-hook.zsh` block to `~/.zshrc`, between the same markers

Then run `exec zsh` in panes that were already open.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/billp/herdr-tweaks/main/uninstall.sh | bash
# also delete the cloned repo:
curl -fsSL https://raw.githubusercontent.com/billp/herdr-tweaks/main/uninstall.sh | bash -s -- --purge
```

Unlinks the plugin, removes the marker blocks from `~/.zshrc` and the herdr config (backups: `*.bak`), clears the sidebar values, and removes the symlink and state. Tab/tile names already set stay until you rename them.

## What you get

| Where | Shows |
|---|---|
| **Tile (pane) label** | the pane's git branch; outside a repo `<agent> · <folder>`, e.g. `claude · ~/Projects` |
| **Tab name** | the branch if all panes share one; otherwise `N branches` (same repo / worktrees), `N repos`, prefixed with `N bash` for panes outside a repo, e.g. `1 bash 2 branches` |
| **Sidebar, spaces** | under each workspace name: the sum over all its tabs, e.g. tabs `1 bash 2 branches` + `1 bash` → `2 bash 2 branches` |
| **Sidebar, agents** | the tile name, falling back to the tab name |

Tab names are always automatic. Tile names you set by hand are kept (unless they look like a folder path).

## How it stays up to date

| Trigger | Source | Latency |
|---|---|---|
| prompt after `cd` / `git checkout` / agent exit | `zsh/herdr-hook.zsh` (precmd) | < 1 s |
| any folder/branch change in the active workspace, any shell | `ui.tab_bar_right` command entry running `herdr-branch-tags --poll` every 1 s (prints nothing; no-op ≈ 0.3 s unless something changed) | 1–2 s |
| pane created / closed / moved, agent detected, tab events | herdr plugin `plugin/herdr-plugin.toml` | < 1 s |

## Files

```
bin/herdr-branch-tags      sync script: [TAB_ID | --spaces | --poll]
plugin/herdr-plugin.toml   herdr event hooks
config/config.toml         herdr config (sidebar rows, poller)
zsh/herdr-hook.zsh         zsh precmd hook
install.sh                 installer
uninstall.sh               uninstaller
```

State lives in `~/.local/state/herdr-branch-tags/` (labels the script set, poll fingerprints, `.poll-heartbeat`).

## License

[MIT](LICENSE)
