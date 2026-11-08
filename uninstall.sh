#!/bin/bash
# Uninstall herdr-tweaks.
#
#   curl -fsSL https://raw.githubusercontent.com/billp/herdr-tweaks/main/uninstall.sh | bash
#
# Removes the plugin, the ~/.local/bin symlink, the herdr-tweaks blocks in
# ~/.config/herdr/config.toml and ~/.zshrc (backups: *.bak), the sidebar
# tokens and the state dir. Tab/tile names already set stay until renamed.
# The cloned repo is kept; pass --purge to delete it too.
set -uo pipefail

DIR="${HERDR_TWEAKS_DIR:-$HOME/Projects/herdr-tweaks}"
HERDR_CFG="$HOME/.config/herdr/config.toml"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/herdr-branch-tags"
BEGIN="# >>> herdr-tweaks >>>"
END="# <<< herdr-tweaks <<<"
say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

strip_block() { # file
  [[ -f "$1" ]] && grep -qF "$BEGIN" "$1" || return 1
  cp "$1" "$1.bak"
  sed "/^$BEGIN\$/,/^$END\$/d" "$1.bak" >"$1"
}

# 1. plugin
herdr plugin unlink local.branch-tags >/dev/null 2>&1 && say "unlinked herdr plugin local.branch-tags"

# 2. herdr config + reload (stops the 1 s poller)
if strip_block "$HERDR_CFG"; then
  say "removed herdr-tweaks block from $HERDR_CFG (backup: $HERDR_CFG.bak)"
  herdr server reload-config >/dev/null 2>&1 && say "reloaded herdr config"
else
  warn "no herdr-tweaks block in $HERDR_CFG; remove tab_bar_right / [ui.sidebar.*] entries by hand if you added them"
fi

# 3. zsh hook
if strip_block "$ZSHRC"; then say "removed zsh hook from $ZSHRC (backup: $ZSHRC.bak)"
else warn "no herdr-tweaks block in $ZSHRC"; fi

# 4. sidebar tokens reported by the script
if command -v herdr >/dev/null && command -v jq >/dev/null; then
  for ws in $(herdr workspace list 2>/dev/null | jq -r '.result.workspaces[].workspace_id'); do
    herdr workspace report-metadata "$ws" --source herdr-branch-tags --clear-token tab_name >/dev/null 2>&1
    for p in $(herdr pane list --workspace "$ws" 2>/dev/null | jq -r '.result.panes[].pane_id'); do
      herdr pane report-metadata "$p" --source herdr-branch-tags --clear-token tile >/dev/null 2>&1
    done
  done
  say "cleared sidebar tokens"
fi

# 5. script symlink + state
target="$HOME/.local/bin/herdr-branch-tags"
if [[ -L "$target" ]]; then rm "$target"; say "removed $target"
elif [[ -e "$target" ]]; then warn "$target is not a symlink; left in place"; fi
rm -rf "$STATE" && say "removed $STATE"

# 6. repo
if [[ "${1:-}" == --purge && -d "$DIR/.git" ]]; then rm -rf "$DIR"; say "deleted $DIR"
else say "kept $DIR (re-run with --purge to delete it)"; fi

say "done — run 'exec zsh' in open panes to drop the prompt hook"
