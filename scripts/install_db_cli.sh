#!/usr/bin/env bash
# Install DB CLI without Homebrew/admin (uses Node + npm in user home).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="$SCRIPT_DIR/db-cli"
FNM_DIR="${HOME}/.local/share/fnm"
NODE_MIN=20

echo "==> Be Electric DB CLI installer (no sudo)"

# Cursor/IDE bundles ship node without npm — require a real Node+npm pair.
node_ok() {
  command -v node >/dev/null 2>&1 \
    && command -v npm >/dev/null 2>&1 \
    && [[ "$(node -p 'process.version' | sed 's/v//' | cut -d. -f1)" -ge "$NODE_MIN" ]]
}

# --- Node via fnm (user install) ---
if ! node_ok; then
  if [[ ! -x "$FNM_DIR/fnm" ]]; then
    echo "==> Installing fnm to $FNM_DIR ..."
    mkdir -p "$FNM_DIR"
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$FNM_DIR" --skip-shell --force-install
  fi
  export PATH="$FNM_DIR:$PATH"
  eval "$(fnm env --use-on-cd 2>/dev/null || fnm env)"
  if ! fnm list 2>/dev/null | grep -q "v${NODE_MIN}"; then
    echo "==> Installing Node ${NODE_MIN} ..."
    fnm install "$NODE_MIN"
  fi
  fnm use "$NODE_MIN"
fi

if ! node_ok; then
  echo "Node ${NODE_MIN}+ with npm is required but not available." >&2
  exit 1
fi

echo "Node: $(node --version)"
echo "npm:  $(npm --version)"

# --- npm dependencies ---
echo "==> Installing postgres driver in scripts/db-cli ..."
cd "$CLI_DIR"
npm install --no-fund --no-audit

# --- shell profile hint ---
PROFILE="${HOME}/.zprofile"
if ! grep -q 'fnm env' "$PROFILE" 2>/dev/null; then
  {
    echo ''
    echo '# fnm (Node) — Be Electric DB CLI'
    echo 'export PATH="$HOME/.local/share/fnm:$PATH"'
    echo 'eval "$(fnm env --use-on-cd 2>/dev/null || fnm env)"'
  } >> "$PROFILE"
  echo "==> Added fnm to $PROFILE"
fi

echo ""
echo "Done. Next steps:"
echo "  1. cp scripts/db.env.example scripts/db.env"
echo "  2. Edit scripts/db.env — set DATABASE_URL (Supabase → Database → URI)"
echo "  3. ./scripts/db.sh check"
echo ""
echo "If 'node' not found in new terminals, run: source ~/.zprofile"
