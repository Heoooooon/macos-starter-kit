#!/usr/bin/env bash
# 03-runtimes.sh — language runtimes: mise (node/python/go) + rustup (rust)

# Edit these to taste; mise resolves "lts"/"latest" at install time.
MISE_TOOLS=("node@lts" "python@latest" "go@latest")

step_runtimes() {
  step "Runtimes: mise (node/python/go) + rustup (rust)"
  load_brew
  have mise   || die "mise not found — run the 'brew' step first."
  have rustup || die "rustup not found — run the 'brew' step first."

  # --- mise-managed runtimes --------------------------------------------
  info "mise: ${MISE_TOOLS[*]}"
  run mise use -g "${MISE_TOOLS[@]}"
  load_mise

  # --- rust via rustup ---------------------------------------------------
  if rustup show active-toolchain >/dev/null 2>&1 \
     && rustup show active-toolchain 2>/dev/null | grep -q .; then
    ok "rust toolchain: $(rustup show active-toolchain 2>/dev/null | head -1)"
  else
    info "Installing Rust stable toolchain…"
    run rustup default stable
  fi
  info "Ensuring rust-analyzer component…"
  if [[ "$DRY_RUN" == "1" ]]; then
    info "[dry-run] rustup component add rust-analyzer"
  else
    rustup component add rust-analyzer >/dev/null 2>&1 || warn "rust-analyzer component add skipped"
  fi

  if [[ "$DRY_RUN" != "1" ]]; then
    ok "node $(node -v 2>/dev/null)  python $(python --version 2>&1 | awk '{print $2}')  go $(go version 2>/dev/null | awk '{print $3}')  $(rustc --version 2>/dev/null)"
  fi
}
