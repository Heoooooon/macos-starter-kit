#!/usr/bin/env bash
# 06-git.sh — git identity + sensible defaults + GitHub auth

step_git() {
  step "git identity + GitHub auth"
  load_brew
  have git || die "git not found."

  # --- gh login (so we can derive identity + wire HTTPS credentials) -----
  if have gh; then
    if gh auth status >/dev/null 2>&1; then
      ok "gh authenticated ($(gh api user --jq .login 2>/dev/null))"
    elif [[ "$DRY_RUN" == "1" ]]; then
      info "[dry-run] gh auth login"
    elif is_tty; then
      info "Launching 'gh auth login' (choose GitHub.com → HTTPS)…"
      gh auth login || warn "gh auth login did not complete"
    else
      warn "gh not authenticated and shell is non-interactive — run 'gh auth login' later"
    fi
    [[ "$DRY_RUN" == "1" ]] || gh auth setup-git >/dev/null 2>&1 || true
  else
    warn "gh CLI not installed — skipping GitHub auth"
  fi

  # --- identity ----------------------------------------------------------
  local cur_name cur_email name email
  cur_name="$(git config --global user.name || true)"
  cur_email="$(git config --global user.email || true)"

  if [[ -n "$cur_name" && -n "$cur_email" ]]; then
    ok "git identity already set: $cur_name <$cur_email>"
  else
    if have gh && gh auth status >/dev/null 2>&1; then
      local login id
      login="$(gh api user --jq .login 2>/dev/null || true)"
      id="$(gh api user --jq .id 2>/dev/null || true)"
      name="$(gh api user --jq '.name // .login' 2>/dev/null || true)"
      [[ -n "$login" && -n "$id" ]] && email="${id}+${login}@users.noreply.github.com"
    fi
    [[ -n "${name:-}" ]]  || name="$(ask 'git author name:' "${cur_name:-}")"
    [[ -n "${email:-}" ]] || email="$(ask 'git author email:' "${cur_email:-}")"

    if [[ -n "${name:-}" && -n "${email:-}" ]]; then
      run git config --global user.name "$name"
      run git config --global user.email "$email"
      ok "git identity: $name <$email>"
    else
      warn "git identity left unset — set later: git config --global user.name/.email"
    fi
  fi

  # --- sensible defaults (only fill if empty; never clobber) -------------
  _git_default() {
    local key="$1" val="$2"
    if [[ -z "$(git config --global "$key" || true)" ]]; then
      run git config --global "$key" "$val"
    fi
  }
  _git_default init.defaultBranch main
  _git_default pull.rebase false
  _git_default push.default simple
  _git_default push.autoSetupRemote true
  ok "git defaults ensured (main branch, autoSetupRemote, …)"
}
