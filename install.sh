#!/usr/bin/env bash
#
# install.sh — verify prerequisites for the VERDICT DFIR agent and (optionally)
# put the launcher on PATH. Path-agnostic: safe to run from any directory.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ok=0; warn=0
say()  { printf '  %s\n' "$*"; }
pass() { printf '  [ok]   %s\n' "$*"; }
miss() { printf '  [MISS] %s\n' "$*"; warn=$((warn+1)); }

echo "VERDICT DFIR agent — prerequisite check"
echo

# 1. The branded fork binary
if command -v "${VERDICT_BIN:-verdict}" >/dev/null 2>&1; then
  pass "verdict binary: $("${VERDICT_BIN:-verdict}" --version 2>/dev/null)"
else
  miss "verdict binary not on PATH — build the fork: https://github.com/TimothyVang/verdict-opencode"
fi

# 2. The toolkit (findevil MCP servers)
HOME_DIR="${VERDICT_DFIR_HOME:-}"
if [ -z "$HOME_DIR" ]; then
  for c in "$(dirname "$ROOT")/dev-verdict-github" "$(dirname "$ROOT")/verdict-dfir-community" "$HOME/verdict-dfir-community"; do
    [ -f "$c/scripts/run-mcp-rust.sh" ] && HOME_DIR="$c" && break
  done
fi
if [ -n "$HOME_DIR" ] && [ -f "$HOME_DIR/scripts/run-mcp-rust.sh" ]; then
  pass "toolkit (VERDICT_DFIR_HOME): $HOME_DIR"
  if [ -x "$HOME_DIR/target/release/findevil-mcp" ]; then
    pass "findevil-mcp (Rust) prebuilt release binary present"
  else
    miss "findevil-mcp release binary missing — first launch will 'cargo run' (slow). Prebuild: (cd \"$HOME_DIR\" && cargo build --release -p findevil-mcp)"
  fi
  command -v uv >/dev/null 2>&1 && pass "uv present (findevil-agent-mcp Python runner)" || miss "uv not found — needed for findevil-agent-mcp (https://docs.astral.sh/uv/)"
else
  miss "toolkit not found — set VERDICT_DFIR_HOME to a verdict-dfir-community checkout"
fi

# 3. A model endpoint (any OpenAI-compatible; user picks the model via /models)
BASE="${VERDICT_LLM_BASEURL:-http://localhost:11434/v1}"
if curl -s --max-time 3 "${BASE%/v1}/api/tags" >/dev/null 2>&1 || curl -s --max-time 3 "$BASE/models" >/dev/null 2>&1; then
  pass "local model endpoint reachable: $BASE"
else
  miss "no local model endpoint at $BASE — start one (e.g. 'ollama serve' + 'ollama pull qwen2.5-coder:7b'), point VERDICT_LLM_BASEURL elsewhere, or use a cloud provider via /models"
fi

echo
if [ "$warn" -eq 0 ]; then
  echo "All prerequisites satisfied. Launch with:  $ROOT/bin/verdict-dfir <case-dir>"
else
  echo "$warn item(s) need attention above. The agent still runs once the [MISS] items are resolved."
fi

# Optional: symlink the launcher onto PATH
if [ "${1:-}" = "--link" ]; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$ROOT/bin/verdict-dfir" "$HOME/.local/bin/verdict-dfir"
  echo "Linked: $HOME/.local/bin/verdict-dfir -> $ROOT/bin/verdict-dfir"
fi
