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
# Allowed disclosures live in scripts/secret-scan.allowlist, each one carrying
# the reason it is allowed. The scanner's own patterns are never edited.
step "secret scan"
SCAN="$HOME/meta/scripts/secret-scan.sh"
ALLOW="scripts/secret-scan.allowlist"

scan_target() { # label, args...
  local label="$1"; shift
  local out hits allowed pats rc
  out=$("$SCAN" "$@" 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then ok "$label clean"; return; fi
  # Hit lines look like "<n>:+<text>"; everything else is scanner chatter.
  hits=$(printf '%s\n' "$out" | grep -E '^[0-9]+:' || true)
  if [ -z "$hits" ]; then
    bad "$label: scanner exited non-zero with no parseable hits"
    printf '%s\n' "$out" | sed 's/^/     /'
    return
  fi
  if [ -f "$ALLOW" ]; then
    # Blank lines are stripped deliberately: an empty pattern matches every
    # line, which would silently allow everything. (It did, once.)
    pats=$(mktemp)
    grep -vE '^[[:space:]]*(#|$)' "$ALLOW" > "$pats" || true
    if [ ! -s "$pats" ]; then
      bad "$ALLOW exists but contains no patterns; refusing to scan against nothing"
      rm -f "$pats"; return
    fi
    allowed=$(printf '%s\n' "$hits" | grep -Ef "$pats" || true)
    hits=$(printf '%s\n' "$hits" | grep -vEf "$pats" || true)
    rm -f "$pats"
    [ -n "$allowed" ] && printf '   OK   %d hit(s) covered by %s\n' \
      "$(printf '%s\n' "$allowed" | wc -l)" "$ALLOW"
  fi
  if [ -z "$hits" ]; then
    ok "$label: no unexamined hits"
  else
    bad "$label: unexamined hit(s)"
    printf '%s\n' "$hits" | sed 's/^/     /'
    printf '     (add to %s ONLY with a stated reason, never to unblock a push)\n' "$ALLOW"
  fi
}

if [ -x "$SCAN" ]; then
  scan_target "staged diff" --staged
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    if git rev-parse --verify origin/main >/dev/null 2>&1; then
      scan_target "origin/main..HEAD" --range origin/main..HEAD
    else
      scan_target "tracked files" --all
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
