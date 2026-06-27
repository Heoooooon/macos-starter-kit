#!/usr/bin/env bash
# 05-docker.sh — Colima + docker CLI plugin wiring

step_docker() {
  step "Containers: Colima + docker CLI plugins"
  load_brew
  have colima || { warn "colima not installed — skipping docker step"; return 0; }

  local plugin_dir; plugin_dir="$(brew_prefix)/lib/docker/cli-plugins"
  local cfg="$HOME/.docker/config.json"

  # --- make `docker compose` / `docker buildx` discoverable --------------
  if [[ "$DRY_RUN" == "1" ]]; then
    info "[dry-run] ensure cliPluginsExtraDirs -> $plugin_dir in $cfg"
  else
    mkdir -p "$HOME/.docker"
    if [[ -s "$cfg" ]] && have jq; then
      tmp="$(mktemp)"
      jq --arg d "$plugin_dir" '
        .cliPluginsExtraDirs = ((.cliPluginsExtraDirs // []) + [$d] | unique)
      ' "$cfg" > "$tmp" && mv "$tmp" "$cfg"
    elif [[ ! -s "$cfg" ]]; then
      cat > "$cfg" <<EOF
{
  "cliPluginsExtraDirs": [
    "$plugin_dir"
  ]
}
EOF
    else
      warn "$cfg exists and jq is missing — add cliPluginsExtraDirs ($plugin_dir) manually"
    fi
    ok "docker CLI plugins wired ($plugin_dir)"
  fi

  # --- start Colima? (heavy: boots a VM, pulls an image) -----------------
  if colima status >/dev/null 2>&1; then
    ok "Colima already running"
  elif [[ "$DRY_RUN" == "1" ]]; then
    info "[dry-run] (optional) colima start --cpu 4 --memory 8 --vm-type vz --vz-rosetta"
  elif confirm "Start Colima now? (downloads a VM image, ~1-2 min)"; then
    run colima start --cpu 4 --memory 8 --vm-type vz --vz-rosetta
    run docker run --rm hello-world >/dev/null 2>&1 && ok "docker verified (hello-world ran)" || \
      warn "colima started but 'docker run' test did not confirm"
  else
    info "Skipped. Start later with:  colima start --cpu 4 --memory 8 --vm-type vz --vz-rosetta"
    info "Auto-start at login:        brew services start colima"
  fi
}
