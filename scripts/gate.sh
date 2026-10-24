#!/usr/bin/env bash
# Pre-push gate for terminal-setup.
#
# This repo ships configuration and documentation, not code with a test suite.
# There is no pytest tier, no browser tier and no lint config, so this gate
# checks the things that can actually be wrong here: the vendored shell script
# still parses, the paths the READMEs promise still exist, and nothing
# sensitive is staged or committed.
#
# A step that cannot run reports SKIP with a reason. A SKIP is not a pass; the
# gate prints what was not covered so it lands in the handoff summary.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

fails=0
skips=()

step() { printf '\n== %s\n' "$*"; }
ok()   { printf '   PASS %s\n' "$*"; }
bad()  { printf '   FAIL %s\n' "$*"; fails=$((fails + 1)); }
skip() { printf '   SKIP %s\n' "$*"; skips+=("$*"); }

# ---------------------------------------------------------------- shell syntax
step "bash syntax"
if bash -n wezterm/wezterm.sh 2>/tmp/gate-bash.err; then
  ok "wezterm/wezterm.sh parses"
else
  bad "wezterm/wezterm.sh: $(cat /tmp/gate-bash.err)"
fi
if bash -n scripts/gate.sh 2>/tmp/gate-self.err; then
  ok "scripts/gate.sh parses"
else
  bad "scripts/gate.sh: $(cat /tmp/gate-self.err)"
fi

# ----------------------------------------------------------------- lua syntax
# WezTerm's own Lua is the only interpreter that matters here, and it is not
# on this box. Without one the config is unverified by this gate.
step "lua syntax"
if command -v luacheck >/dev/null 2>&1; then
  if luacheck --no-color --no-max-line-length wezterm/wezterm.lua; then
    ok "luacheck clean"
  else
    bad "luacheck reported problems"
  fi
elif command -v luac >/dev/null 2>&1; then
  if luac -p wezterm/wezterm.lua; then
    ok "luac -p clean"
  else
    bad "luac -p reported a syntax error"
  fi
else
  skip "no lua/luac/luacheck on PATH — wezterm.lua is not syntax-checked here."
  skip "the real check is WezTerm loading it on Windows (Ctrl+Shift+R reloads)."
fi

# ------------------------------------------------------------- README paths
# The original README referenced files that did not exist (.wezterm.lua,
# toolsbox/.vimrc). Anything a README tells a reader to copy must be present.
step "README paths exist"
missing=0
for f in $(grep -ohP '(?<![\w./-])wezterm/[\w.-]+' README.md wezterm/README.md | sort -u); do
  if [ -e "$f" ]; then
    ok "$f"
  else
    bad "README references $f, which does not exist"
    missing=$((missing + 1))
  fi
done
[ "$missing" -eq 0 ] || bad "$missing README path(s) missing"

# --------------------------------------------------------------- secret scan
# The house scanner is deliberately NOT vendored into this repo: its pattern
# list names internal hostnames, which is exactly what must not be published.
step "secret scan"
SCAN="$HOME/meta/scripts/secret-scan.sh"
if [ -x "$SCAN" ]; then
  if "$SCAN" --staged; then ok "staged diff clean"; else bad "secret scan: staged hits"; fi
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    if git rev-parse --verify origin/main >/dev/null 2>&1; then
      if "$SCAN" --range origin/main..HEAD; then ok "origin/main..HEAD clean"
      else bad "secret scan: committed hits"; fi
    else
      if "$SCAN" --all; then ok "all tracked files clean"
      else bad "secret scan: tracked-file hits"; fi
      skip "no origin/main yet — scanned every tracked file instead"
    fi
  fi
else
  skip "$SCAN not found — nothing was scanned. Do not push without a scan."
fi

# ------------------------------------------------------------------- summary
printf '\n== summary\n'
printf '   failures: %d\n' "$fails"
if [ "${#skips[@]}" -gt 0 ]; then
  printf '   NOT COVERED (say these in the handoff):\n'
  for s in "${skips[@]}"; do printf '     - %s\n' "$s"; done
fi

if [ "$fails" -ne 0 ]; then
  printf '\nREFUSED\n'
  exit 1
fi
printf '\nGATE PASSED (with the skips listed above)\n'
