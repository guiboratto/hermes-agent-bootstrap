#!/usr/bin/env bash
# bootstrap-hermes.sh — setup script for Hermes Agent.
# Idempotent: safe to re-run.
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: $0 [--bundle PATH] [--non-interactive]
EOF
}

SKILLS_BUNDLE=""
NON_INTERACTIVE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bundle)          SKILLS_BUNDLE="$2"; shift 2 ;;
    --non-interactive) NON_INTERACTIVE=1; shift ;;
    -h|--help)         usage; exit 0 ;;
    *)                 echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

command -v hermes >/dev/null || { echo "hermes CLI required"; exit 1; }

ask() {
  local q="$1"
  if [[ $NON_INTERACTIVE -eq 1 ]]; then return 0; fi
  local ans
  read -r -p "$q [y/N]: " ans
  [[ "${ans,,}" == "y" ]]
}

# 1. Backup
[[ -d "$HERMES_HOME" && ! -f "$HERMES_HOME/.pre-bootstrap.bak.tar" ]] && \
  tar czf "$HERMES_HOME/.pre-bootstrap.bak.tar" -C "$HOME" .hermes

# 2. Self-update + diagnostics
hermes doctor --fix >/dev/null 2>&1 || true
hermes update >/dev/null 2>&1 || true
hermes skills repair-official >/dev/null 2>&1 || true

# 3. Skills from bundle (if provided or co-located)
if [[ -z "$SKILLS_BUNDLE" && -f "$SCRIPT_DIR/hermes-skills-bundle.tar.gz" ]]; then
  SKILLS_BUNDLE="$SCRIPT_DIR/hermes-skills-bundle.tar.gz"
fi
if [[ -n "$SKILLS_BUNDLE" && -f "$SKILLS_BUNDLE" ]]; then
  mkdir -p "$HERMES_HOME/skills"
  tar xzf "$SKILLS_BUNDLE" -C "$HERMES_HOME/skills/"
fi

# 4. Recommended skills (inspect → install)
declare -A SKILLS=(
  ["archify"]="official/creative/archify"
  ["i-have-adhd"]="ayghri/i-have-adhd"
)
for name in "${!SKILLS[@]}"; do
  id="${SKILLS[$name]}"
  if ask "Install skill '$name' ($id)?"; then
    hermes skills inspect "$id" >/dev/null 2>&1 || true
    hermes skills install "$id" || echo "  failed: $id"
  fi
done

# 5. Recommended plugins
for plugin in custodian handflow git-hook; do
  if ask "Install plugin '$plugin'?"; then
    hermes plugins install "$plugin" || echo "  failed: $plugin"
  fi
done

# 6. Done
echo
echo "Hermes bootstrap complete. Next:"
echo "  hermes skills list"
echo "  hermes plugins list"
echo "  hermes mcp catalog"