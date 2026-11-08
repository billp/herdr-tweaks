#!/bin/bash
# Install herdr-tweaks: branch-named tabs/tiles + sidebar tweaks for herdr.
#
#   curl -fsSL https://raw.githubusercontent.com/billp/herdr-tweaks/main/install.sh | bash
#
# Idempotent (safe to re-run; also updates). HERDR_TWEAKS_DIR sets the clone
# location (default ~/Projects/herdr-tweaks). Undo with uninstall.sh.
set -euo pipefail

REPO_URL="https://github.com/billp/herdr-tweaks.git"
DIR="${HERDR_TWEAKS_DIR:-$HOME/Projects/herdr-tweaks}"
HERDR_CFG="$HOME/.config/herdr/config.toml"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
BEGIN="# >>> herdr-tweaks >>>"
END="# <<< herdr-tweaks <<<"
say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

for cmd in herdr git jq; do
  command -v "$cmd" >/dev/null || { warn "missing dependency: $cmd"; exit 1; }
done

# 1. repo: use the checkout this script runs from, else clone / update
here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [[ -n "$here" && -f "$here/bin/herdr-branch-tags" ]]; then
  DIR="$here"
elif [[ -d "$DIR/.git" ]]; then
  say "updating $DIR"; git -C "$DIR" pull --ff-only --quiet
else
  say "cloning into $DIR"; mkdir -p "$(dirname "$DIR")"; git clone --quiet "$REPO_URL" "$DIR"
fi

# 2. script -> ~/.local/bin (symlink, so `git pull` updates it)
mkdir -p "$HOME/.local/bin"
target="$HOME/.local/bin/herdr-branch-tags"
if [[ -e "$target" && ! -L "$target" ]]; then
  mv "$target" "$target.bak"; warn "moved existing $target to $target.bak"
fi
ln -sfn "$DIR/bin/herdr-branch-tags" "$target"
say "linked $target"

# 3. herdr event plugin (pane open/close/move, agent detected, tab events)
herdr plugin unlink local.branch-tags >/dev/null 2>&1 || true
if herdr plugin link "$DIR/plugin" >/dev/null; then say "linked herdr plugin local.branch-tags"
else warn "could not link the herdr plugin; run: herdr plugin link $DIR/plugin"; fi

# 4. herdr config: 1 s poller + sidebar rows, between markers
mkdir -p "$(dirname "$HERDR_CFG")"; touch "$HERDR_CFG"
if grep -qF "$BEGIN" "$HERDR_CFG"; then
  cp "$HERDR_CFG" "$HERDR_CFG.bak"
  { sed "/^$BEGIN\$/,/^$END\$/d" "$HERDR_CFG.bak"; cat "$DIR/config/config.toml"; } >"$HERDR_CFG"
  say "updated herdr-tweaks block in $HERDR_CFG"
elif grep -qE '^\[ui(\.sidebar(\.agents|\.spaces)?)?\]|^tab_bar_right' "$HERDR_CFG"; then
  warn "$HERDR_CFG already defines [ui] / [ui.sidebar.*]; merge this by hand:"
  cat "$DIR/config/config.toml"
else
  cp "$HERDR_CFG" "$HERDR_CFG.bak"
  { [[ -s "$HERDR_CFG.bak" ]] && echo; cat "$DIR/config/config.toml"; } >>"$HERDR_CFG"
  say "added herdr-tweaks block to $HERDR_CFG (backup: $HERDR_CFG.bak)"
fi
if herdr server reload-config >/dev/null 2>&1; then say "reloaded herdr config"
else warn "herdr server not running; config applies on next start"; fi

# 5. zsh prompt hook (instant updates on cd / git checkout)
touch "$ZSHRC"
if grep -qF "$BEGIN" "$ZSHRC"; then
  say "zsh hook already in $ZSHRC"
else
  printf '\n%s\n[[ -f "%s/zsh/herdr-hook.zsh" ]] && source "%s/zsh/herdr-hook.zsh"\n%s\n' \
    "$BEGIN" "$DIR" "$DIR" "$END" >>"$ZSHRC"
  say "added zsh hook to $ZSHRC"
fi

"$target" >/dev/null 2>&1 || true
say "done — run 'exec zsh' in panes that were already open"
