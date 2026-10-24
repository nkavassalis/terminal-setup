# AGENTS.md — terminal-setup

## Mode

**REAL.** GitHub-hosted at `nkavassalis/terminal-setup`, **public** (Nick chose
public explicitly). Branch + PR, gate before any push, secret scan before every
commit.

## Purpose

Nick's terminal configuration, published so it can be copied rather than
eyeballed. Today that is one bundle: WezTerm on Windows 11 driving WSL2 Ubuntu,
with a one-key SSH hop into a home-lab box running
[herdr](https://herdr.dev). Ghostty on macOS/Linux is planned and **does not
exist yet**.

The one-line spirit: *a config you can actually install — nothing fetched at
install time, every personal value named.*

## Layout

```
terminal-setup/
├── README.md              Map of the bundles. Not the install instructions.
├── AGENTS.md              This file
├── CHANGELOG.md           Notable changes, newest first
├── LICENSE                MIT (house license)
├── .gitignore             Keys, .env, editor droppings, *.local.lua
├── scripts/
│   └── gate.sh            Pre-push gate (see "How to test")
└── wezterm/               The one real bundle -> wezterm/README.md
    ├── README.md          Install, keys, per-machine settings, troubleshooting
    ├── wezterm.lua        WezTerm config (copied to %USERPROFILE%\.wezterm.lua)
    ├── wezterm.sh         Vendored upstream shell-integration script (MIT)
    └── vimrc              vim config for the remote box (copied to ~/.vimrc)
```

`ghostty/` is intentionally absent. Do not create it on a hunch; see Open
questions.

## How to run

There is nothing to run on this box. The artifacts are installed elsewhere:

- `wezterm.lua` → copied to `C:\Users\<you>\.wezterm.lua`; WezTerm hot-reloads
  it (Ctrl+Shift+R).
- `wezterm.sh` → copied to `~/.config/wezterm/wezterm.sh` in WSL (and on the
  remote box), then sourced from `~/.bashrc`.
- `vimrc` → copied to `~/.vimrc` on the remote box.

Exact commands are in `wezterm/README.md`. Keep that file as the single place
install steps live; the parent README stays a map.

## How to test

```bash
scripts/gate.sh
```

It runs, in order: `bash -n` on `wezterm.sh` and itself; a Lua syntax check
(`luacheck`, else `luac -p`, else **SKIP** — neither is installed on this box);
a check that every `wezterm/<file>` path mentioned in either README actually
exists; and the house secret scan (`~/meta/scripts/secret-scan.sh`, staged plus
tracked files). It prints a `NOT COVERED` list, which belongs verbatim in the
handoff summary.

There is no pytest tier, no browser tier and no lint config — this repo has no
application code. Do not add a test framework to satisfy a checklist; add a
check only for something that has actually gone wrong here.

The only real verification of `wezterm.lua` is WezTerm loading it on Windows.

## Design decisions and why

**Nothing is downloaded at install time.** `wezterm.sh` is vendored rather than
`curl`ed from `raw.githubusercontent.com`. Nick did not want the install path to
depend on, or silently execute, whatever is on a remote server that day. The
file is byte-identical to upstream except three lines where tabs became spaces
(verified with `diff` against `main`). Refresh it by diffing against
`assets/shell-integration/wezterm.sh` upstream by hand — no automated sync.

**The scanner is not vendored.** `scripts/gate.sh` calls
`~/meta/scripts/secret-scan.sh` instead of copying it in, because the pattern
list names internal hostnames. Publishing the scanner would publish the
topology it protects against. If the scanner is missing the gate SKIPs loudly;
that is not a pass.

**`wezterm.lua` is a real working config, not a sanitized template.** It keeps
the author's literal username, home directory and home-LAN address as an
example, and both READMEs say so and list every value to replace. Nick's
explicit call: the address is RFC 1918 on his home network, unreachable from
the internet, so publishing it is worth less than publishing something a reader
can see working. The house rule says LAN IPs stay out of tracked files — this
is a deliberate, owner-approved exception, and it applies to *that* value only.
New secrets, credentials, work-network addresses or real hostnames still don't
get that pass.

**WezTerm's built-in SSH, not ssh-inside-WSL.** `multiplexing = 'None'`,
command set via `default_prog`. Running ssh inside a WSL tab pushes herdr's
palette queries through ConPTY, which splits the replies and types `rgb:8787/…`
junk into herdr. Documented in the troubleshooting section; do not "simplify"
this back to ssh-in-a-tab.

**Chrome link handling has two entry points on purpose.** `open-uri` covers a
normal click; Ctrl+Shift+O rebuilds a URL from the selection (or the clipboard,
for herdr's OSC 52 copies), strips U+2500–U+257F box-drawing so pane borders
don't leak in, and joins the wrapped pieces. Chrome is found by probing three
install paths at config load, and non-`http(s)` schemes deliberately fall
through to WezTerm.

**Two READMEs, different jobs.** Parent = map + cross-bundle conventions.
Bundle = install + troubleshooting. The parent must never duplicate install
steps, because they drift.

## Invariants

- **No private key material, tokens or credentials in any tracked file.**
  `id_ed25519` may appear only as a filename in a path string.
- **No downloads during install.** Any third-party file is vendored, with its
  upstream source named in the bundle README.
- **READMEs use placeholders** (`<WINDOWS_USER>`, `<WSL_USER>`,
  `<TOOLSBOX_HOST>`, `<REMOTE_USER>`) and never name a real host, IP or home
  path — even though the checked-in config does, per the decision above.
- **Every path a README tells the reader to copy exists in the repo.** The
  first version of this README referenced `wezterm/.wezterm.lua` and
  `toolsbox/.vimrc`; neither existed. `gate.sh` now enforces it.
- **Docs match the config.** New key binding, new binding target, new
  behaviour in `wezterm.lua` → the key table, the feature bullets and the
  per-machine table in `wezterm/README.md` all change in the same commit.
- **`wezterm.sh` stays upstream-identical** apart from whitespace. No local
  patches; if it needs one, that's a decision to record here first.
- **`ghostty/` stays absent until someone writes it.**

## Conventions

- Bundles are self-contained and installable on their own.
- Troubleshooting entries are written from failures that actually happened, in
  the voice "this happened, here's the mechanism, here's the fix". No
  speculative advice. If you did not observe it, it does not go in that section.
- House MIT license, same text as the other REAL projects.
- Git author email is the GitHub noreply address
  (`232769+nkavassalis@users.noreply.github.com`), set repo-locally, so the
  personal address never lands in published history.
- Commit messages: imperative, why over what.

## Known issues / TODOs

- `wezterm/README.txt` is a 0-byte stray, untracked. Delete it or leave it;
  Nick hasn't said.
- No Lua syntax checking is possible on this box (no `lua`/`luac`/`luacheck`),
  so `gate.sh` always SKIPs that step here.
- Ghostty bundle: see the open questions in the parent README (which WezTerm
  behaviors to reproduce, remote shell integration on macOS/Linux, one
  OS-conditional config vs. two).
- The vendored `wezterm.sh` has no automated freshness check — it will drift
  silently until someone diffs it.

## Testing limitations / unverified

Say these out loud rather than implying coverage:

- **`wezterm.lua` has never been loaded by WezTerm from this machine or by any
  agent.** No syntax check has run (no Lua interpreter installed). A typo in it
  would only show up as WezTerm refusing the config on Windows.
- **The Chrome link features are documented from the code, not from observed
  behavior.** In particular the Shift+left-click-to-open-link binding inside
  herdr is inferred from the config's own comment plus the same mouse-capture
  logic as Shift+right-click paste. Nick should confirm it by hand.
- The two link-related troubleshooting entries describe code paths
  (`Chrome not found`, first-match-wins on multiple URLs); they were reasoned
  out, not reproduced.
- `wezterm.sh` was verified against upstream `main` by `diff` on 2026-10-24.
  That says nothing about later upstream changes.
- `gate.sh` itself has been run (`bash -n` plus a live run), but its
  failure paths — a missing README path, a scanner hit — have not been
  exercised with a deliberately broken input.
- Nothing about the remote box (herdr install, `~/.vimrc`, remote titles) has
  been verified from here.

## Do not touch

- **Any private key**, anywhere. `~/.ssh` is off-limits; never read or copy
  private key contents into this repo.
- `wezterm/wezterm.sh` — vendored. Diff against upstream instead of editing.
- The SSH domain's `multiplexing = 'None'` + `default_prog` combination — it
  exists to dodge a ConPTY bug (see Design decisions).
- `.gitignore`'s key patterns and the `*.local.lua` line.
- The repo's local `user.email` (noreply) and the pre-push hook.
- `~/meta` — local-only, never pushed, and its scanner stays out of this repo.

## Guardrails in effect

- `scripts/gate.sh` runs on pre-push; `ALLOW_REMOTE_GIT_PUSH=1` is the only
  bypass and only when Nick asks in plain words.
- Secret scan runs on the staged diff and on tracked files inside the gate. It
  is not vendored (see Design decisions) so it can silently no-op if `~/meta`
  is absent — the gate prints a SKIP saying "Do not push without a scan." Read
  the summary, don't just read the exit code.
- `.gitignore` blocks private keys, `.env`, logs and `*.local.*` overrides.
- Repo-local git identity is the GitHub noreply address.
- `gh auth status` must report `nkavassalis` before any push.
