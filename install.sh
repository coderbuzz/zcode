#!/usr/bin/env bash
# install.sh — build zcode and put the `zh` headless launcher on PATH.
#
#   ./install.sh              install for the current user (~/.local/bin)
#   ZH_BIN_DIR=/usr/local/bin ./install.sh     custom bin dir
#
# Steps: ensure bun → pnpm install → build CLI bundle → link bin/zh.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${ZH_BIN_DIR:-$HOME/.local/bin}"

log() { printf '[install] %s\n' "$1"; }

# 1. Bun (preferred runtime for zh; Node still works as a fallback).
if ! command -v bun >/dev/null 2>&1; then
  log "bun not found, installing to ~/.bun ..."
  curl -fsSL https://bun.sh/install | bash
  export PATH="$HOME/.bun/bin:$PATH"
fi
log "bun $(bun --version)"

# 2. pnpm (workspace dependency linking).
if ! command -v pnpm >/dev/null 2>&1; then
  log "pnpm not found, enabling via corepack ..."
  corepack enable >/dev/null 2>&1 || npm install -g pnpm >/dev/null
fi
log "pnpm $(pnpm --version)"

# 3. Dependencies + CLI bundle.
log "installing workspace dependencies (this can take a few minutes) ..."
pnpm --dir "$repo_root" install --frozen-lockfile

log "building CLI bundle ..."
pnpm --dir "$repo_root/apps/zcode-cli" run build

dist="$repo_root/apps/zcode-cli/packages/cli/dist/zcode.cjs"
if [[ ! -f "$dist" ]]; then
  echo "[install] build finished but $dist is missing." >&2
  exit 1
fi

# 4. Link the launcher.
mkdir -p "$bin_dir"
ln -sf "$repo_root/bin/zh" "$bin_dir/zh"
log "linked $bin_dir/zh -> $repo_root/bin/zh"

if ! command -v zh >/dev/null 2>&1; then
  log "note: $bin_dir is not on PATH; add 'export PATH=\"$bin_dir:\$PATH\"' to your shell profile."
fi

log "done. try: zh --version"
