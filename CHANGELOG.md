# Changelog

Notable changes. Newest first.

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
  existence, secret scan), `.gitignore`, `LICENSE` (MIT), `AGENTS.md`.
