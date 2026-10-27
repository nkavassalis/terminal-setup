# Changelog

Notable changes. Newest first.

## Unreleased

- `wezterm/README.md`: new troubleshooting entry for the palette-query spew
  (`rgb:…`, `d7d7`, `afaf`, `5f5f`) that appears on **reattach** even via
  WezTerm's built-in SSH — distinct from the existing ConPTY entry. Explains
  the race (herdr detaches before consuming WezTerm's OSC 10/11 / DC color
  reply, which then lands on the `exec bash -l` prompt), that it is cosmetic,
  and to check `herdr status` for client/server version skew first.
- Deleted the 0-byte stray `wezterm/README.txt` (untracked; Nick approved).
- `wezterm.lua`: `enable_kitty_keyboard` flipped `true` -> `false`. With it on,
  WezTerm on Windows 11 dropped Shift-modified character keys entirely — `A`,
  `?`, `!`, `I` produced no bytes on the pty (Nick confirmed with
  `stty raw -echo; cat -v`). Upstream wezterm/wezterm#6900 and #7437. Trade:
  agent CLIs lose Shift+Enter chords. `enable_kitty_graphics` is a separate
  protocol and is unaffected.
- New troubleshooting entry for the dropped Shift keys, including the raw-pty
  reproduction command; the "vim keys act oddly" entry and the Kitty feature
  bullet updated to match.

## 2026-10-24 — initial public release

- First commit of the `wezterm/` bundle: `wezterm.lua`, the vendored
  `wezterm.sh` shell-integration script, and `vimrc` for the remote box.
- `wezterm/README.md` rewritten. Install no longer `curl`s the shell-integration
  script from `raw.githubusercontent.com`; it copies the vendored
  `wezterm/wezterm.sh` instead. Paths corrected — the previous version told
  readers to copy `wezterm/.wezterm.lua` and `toolsbox/.vimrc`, neither of
  which exists.
- Documentation now uses placeholders (`<WINDOWS_USER>`, `<WSL_USER>`,
  `<TOOLSBOX_HOST>`, `<REMOTE_USER>`) throughout, with a table of every
  personal value to replace in `wezterm.lua`.
- Documented Chrome link handling: `open-uri` for clicks, Ctrl+Shift+O to
  rebuild a soft-wrapped URL from the selection or the clipboard, Chrome
  discovery paths, and the Chrome profile flag.
- New `README.md` at the repo root: bundle map, cross-bundle conventions, and
  the planned-but-unwritten `ghostty/` bundle (macOS/Linux) with its open
  questions.
- Added `scripts/gate.sh` (shell syntax, optional Lua syntax check, README path
  existence, secret scan), `scripts/secret-scan.allowlist`, `.gitignore`,
  `LICENSE` (MIT), `AGENTS.md`. The gate's failure paths were exercised with a
  planted token and a bogus README path.
