# herdr-tweaks: label each pane with its git branch and the tab with the
# shared branch (or "N branches" / "N repos" / "N bash"). Runs on every prompt
# (in the background) so cd, git checkout and an agent exiting back to the
# shell re-tag the tab immediately. See bin/herdr-branch-tags.
if [[ "${HERDR_ENV:-}" == 1 ]]; then
  _herdr_tab_branch() {
    herdr-branch-tags "$HERDR_TAB_ID" >/dev/null 2>&1 &!
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _herdr_tab_branch
fi
