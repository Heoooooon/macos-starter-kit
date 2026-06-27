#!/usr/bin/env bash
# 01-prereqs.sh — Xcode Command Line Tools + Homebrew

step_prereqs() {
  step "Prerequisites: Xcode CLT + Homebrew"

  # --- Xcode Command Line Tools (git, clang, make, headers) -------------
  if xcode-select -p >/dev/null 2>&1; then
    ok "Xcode Command Line Tools present ($(xcode-select -p))"
  else
    info "Installing Xcode Command Line Tools…"
    if [[ "$DRY_RUN" == "1" ]]; then
      info "[dry-run] xcode-select --install"
    else
      xcode-select --install >/dev/null 2>&1 || true
      info "A system dialog opened — click Install and wait for it to finish."
      until xcode-select -p >/dev/null 2>&1; do
        sleep 15; info "…waiting for Command Line Tools to finish installing"
      done
      ok "Xcode Command Line Tools installed"
    fi
  fi

  # --- Homebrew ----------------------------------------------------------
  if [[ -x "$(brew_prefix)/bin/brew" ]]; then
    ok "Homebrew present ($(brew_prefix))"
  else
    info "Installing Homebrew…"
    if [[ "$DRY_RUN" == "1" ]]; then
      info "[dry-run] /bin/bash -c \"\$(curl -fsSL .../Homebrew/install/HEAD/install.sh)\""
    else
      NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      ok "Homebrew installed"
    fi
  fi

  load_brew

  # --- persist brew shellenv to ~/.zprofile (managed block) -------------
  local p; p="$(brew_prefix)"
  inject_block "$HOME/.zprofile" "macos-starter-kit:brew" <<EOF
eval "\$($p/bin/brew shellenv)"
EOF
}
