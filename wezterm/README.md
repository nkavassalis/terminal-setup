# wezterm-dotfiles

WezTerm on Windows 11 with WSL2 Ubuntu as the default shell, plus a one-key
SSH connection to a remote box (referred to below as `toolsbox`) that drops
straight into [herdr](https://herdr.dev).

Everything needed to install is in this directory — nothing is downloaded at
install time.

## Layout

| Path | What it is |
|---|---|
| `wezterm/wezterm.lua` | WezTerm config (Windows side). Copied to `%USERPROFILE%\.wezterm.lua` |
| `wezterm/wezterm.sh` | Vendored WezTerm shell-integration script (from the [wezterm repo](https://github.com/wezterm/wezterm), `assets/shell-integration/wezterm.sh`, MIT). Used for tab titles |
| `wezterm/vimrc` | vim config for the remote box. Copied to `~/.vimrc` there |
| `wezterm/README.md` | This file |

## Placeholders used in this README

Substitute your own values. Nothing here is machine-specific.

| Placeholder | Meaning | Example |
|---|---|---|
| `<WINDOWS_USER>` | Your Windows account name | `alice` |
| `<WSL_USER>` | Your username inside WSL Ubuntu | `alice` |
| `<TOOLSBOX_HOST>` | Hostname or IP of your remote box | `192.0.2.10` or `box.example.net` |
| `<REMOTE_USER>` | Username on the remote box | `alice` |

The checked-in `wezterm.lua` is a real working config, not a sanitized
template — it still contains the original author's username, home directory
and LAN address as literal values. Treat those as examples and replace them
(see "Configure for your machine"). No private keys or credentials are in this
repo.

## What the WezTerm config does

- Opens WSL Ubuntu by default, with new tabs starting in your home directory
  (both Ctrl+Shift+T and the `+` button)
- Ubuntu aubergine color scheme matching Windows Terminal
- Starts at 160×48
- Windows Terminal-style paste: Ctrl+V, right-click, and Shift+right-click
  (the last works even inside herdr/vim, which capture the mouse)
- Tab titles show the running program or current directory instead of
  `wslhost.exe` (needs shell integration, below)
- Window title shows `[n/total] WezTerm`
- `http(s)` links open in Chrome rather than the default browser, including
  URLs that were soft-wrapped across lines (see "Links", below)
- `toolsbox` SSH domain using WezTerm's built-in SSH client, which starts
  herdr on connect
- Kitty keyboard and graphics protocols on, so agents in herdr get
  Shift+Enter and similar chords, and herdr can render images

## Key bindings

| Keys | Action |
|---|---|
| Ctrl+Shift+T | New WSL tab in `~` |
| Ctrl+Shift+S | New tab on toolsbox, straight into herdr |
| Ctrl+V / Ctrl+Shift+V / Shift+Insert | Paste |
| Right-click | Paste (when no app is capturing the mouse) |
| Shift+right-click | Paste, even inside herdr or vim |
| Ctrl+Q (in vim) | Visual block, since Ctrl+V is paste |
| Ctrl+Shift+O | Open the selected (or copied) URL in Chrome |
| Ctrl+Shift+R | Reload WezTerm config |
| Shift+left-click | Open a link in Chrome, even inside herdr |

## Links

Two paths, both ending in Chrome rather than whatever Windows thinks the
default browser is.

**Clicking.** `open-uri` handles a normal link click and opens it in Chrome if
the URL starts with `http://` or `https://`. Anything else — `mailto:`,
`file:`, and so on — returns without acting, so WezTerm's default handling
applies. Inside herdr, which captures the mouse, use Shift+click.

**Rebuilding a wrapped URL.** Ctrl+Shift+O takes the current WezTerm selection
and reconstructs a URL from it, which is what you need when a long URL has
been soft-wrapped across lines or broken by herdr's pane borders. It:

1. Reads the WezTerm selection; if there is none, falls back to the Windows
   clipboard via `Get-Clipboard -Raw`. That fallback is what makes it work
   after a copy from herdr's copy mode, which goes out over OSC 52 rather than
   into a WezTerm selection.
2. Strips box-drawing characters (U+2500–U+257F) so pane borders drawn around
   the text don't end up inside the URL.
3. Removes all remaining whitespace, joining the wrapped pieces.
4. Matches the first `https?://…` in the result, stopping at a quote, angle
   bracket, or backtick.

On success the selection is cleared. On failure you get a toast — `Chrome not
found` or `No URL found in selection`.

**Finding Chrome.** Chrome is located once at config load by testing three
paths in order:

```
C:\Program Files\Google\Chrome\Application\chrome.exe
C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe
```

To open links in a specific Chrome profile, add `--profile-directory=…` to the
argument list in `open_in_chrome` (there's a comment marking the spot). Note
that the flag must come before the URL.

## Configure for your machine

`wezterm/wezterm.lua` has a handful of personal values, all inside the
`wsl_domains` and `ssh_domains` blocks near the top of the file plus one line
in the tab-title formatter. The Chrome paths are the usual install locations
and only need changing for a non-standard install.

| In `wezterm.lua` | Set to |
|---|---|
| `wsl_domains[1].username` | `<WSL_USER>` |
| `wsl_domains[1].default_cwd` | `/home/<WSL_USER>` |
| `spawn_home` `cwd` | `/home/<WSL_USER>` |
| `ssh_domains[1].remote_address` | `<TOOLSBOX_HOST>` |
| `ssh_domains[1].username` | `<REMOTE_USER>` |
| `ssh_domains[1].default_prog` | absolute path to your `herdr` binary |
| `ssh_domains[1].ssh_option.identityfile` | `C:/Users/<WINDOWS_USER>/.ssh/id_ed25519` |
| `format-tab-title` home-dir match | `/home/<WSL_USER>/?$` |
| `chrome_paths` | Only if Chrome is installed somewhere unusual |
| `open_in_chrome` args | Add `--profile-directory=…` before the URL to pin a Chrome profile |

The `toolsbox` name is yours to rename — it appears in the domain name, the
tab-title label, and nowhere else.

## Install

Run the commands below from the directory that contains `wezterm/`.

### 1. WezTerm config (Windows)

Copy the config to your Windows home directory. In PowerShell, from the repo root:

```powershell
copy wezterm\wezterm.lua $env:USERPROFILE\.wezterm.lua
```

WezTerm reloads the config automatically. Window-size changes apply to new
windows.

### 2. Shell integration (WSL, and optionally toolsbox)

This makes tab titles show `vim notes.md`, `herdr`, or the directory name.
The script is vendored in this repo, so no network fetch is involved.

Run inside WSL:

```bash
mkdir -p ~/.config/wezterm
cp wezterm/wezterm.sh ~/.config/wezterm/wezterm.sh
echo '[ -n "$WEZTERM_PANE" ] && . ~/.config/wezterm/wezterm.sh' >> ~/.bashrc
```

Remove any hand-rolled title-setting from your prompt in `~/.bashrc`. The
script works best with `bash-preexec`, and will tell you if it's missing.

To get titles in toolsbox tabs too, install it there the same way — copy the
vendored file across, then drop the `$WEZTERM_PANE` check. That variable may
not be set over SSH:

```bash
scp wezterm/wezterm.sh <REMOTE_USER>@<TOOLSBOX_HOST>:~/.config/wezterm/wezterm.sh
ssh <REMOTE_USER>@<TOOLSBOX_HOST> \
  "echo '. ~/.config/wezterm/wezterm.sh' >> ~/.bashrc"
```

To refresh the vendored copy later, diff it against
`assets/shell-integration/wezterm.sh` in the upstream wezterm repository and
replace it by hand.

### 3. SSH key for toolsbox (Windows)

WezTerm's SSH client is a Windows program, so it reads
`C:\Users\<WINDOWS_USER>\.ssh`, not your WSL `~/.ssh`. Copy the key toolsbox
accepts (`id_ed25519`) to the Windows side:

```powershell
mkdir $env:USERPROFILE\.ssh -Force
copy \\wsl$\Ubuntu\home\<WSL_USER>\.ssh\id_ed25519* $env:USERPROFILE\.ssh\
```

To check which key a host accepts, run this from WSL:

```bash
ssh -v <TOOLSBOX_HOST> exit 2>&1 | grep -E 'Offering|Server accepts'
```

**Never commit private keys to this repo.** Only `id_ed25519.pub` belongs in
version control, and even that is not needed here.

### 4. vim config (toolsbox)

```bash
scp wezterm/vimrc <REMOTE_USER>@<TOOLSBOX_HOST>:~/.vimrc
```

### 5. herdr (toolsbox)

herdr must be installed at the absolute path named in
`ssh_domains[1].default_prog` in `wezterm.lua`, because the WezTerm SSH domain
calls it directly. If it lives elsewhere, run `which herdr` on toolsbox and
update that line.

Plain `ssh <REMOTE_USER>@<TOOLSBOX_HOST>` from WSL is unaffected and gives a
normal shell.

## Troubleshooting

Each of these came up during setup.

**`rgb:8787/...` junk typed into herdr on attach.** herdr queries the outer
terminal's color palette on attach, and the replies get split apart passing
through ConPTY (WSL → ssh). Connect with Ctrl+Shift+S instead of running ssh
inside a WSL tab, since WezTerm's built-in SSH client bypasses ConPTY. Also
keep herdr updated (`herdr update`, then `herdr server stop` and reattach),
because these leak fixes change from release to release.

**Same `rgb:`/`d7d7`/`afaf` spew, but on reattach, even via Ctrl+Shift+S.**
Different mechanism, same family. The garbage is not corruption — it is
WezTerm *answering* herdr's palette query (OSC 10/11 and the DC color report
return doubled-hex components like `d7d7`, `afaf`, `5f5f`, `8787`). WezTerm
always answers; herdr is supposed to read the reply. When an attach tears down
early — slow link, resize storm, or a client/server version skew — herdr
detaches before consuming it, the `exec bash -l` fallback in `default_prog`
comes up, and the reply is typed onto the bash prompt as literal input. It is
occasional because it is a race between herdr's read window and the reply.
What to do:

- It is cosmetic. Press Ctrl+C; the line is gone and nothing was executed
  (`rgb:` is not a command). If it landed *inside* a herdr pane's input,
  clear the line before running anything.
- Check the skew first: `herdr status` on toolsbox. If `client` and `server`
  versions differ or `server_binary_stale: yes`, run `herdr update`, then
  `herdr server stop`, then reconnect. A stale server is the most common
  trigger for the early detach.
- If it happens on *every* reattach rather than occasionally, that is not this
  race — report it upstream with the `herdr status` output and your WezTerm
  version.

There is no WezTerm-side switch to stop answering these queries, and herdr
0.9.5 has no config knob to stop asking; the fix lives in whichever side wins
the race.

**SSH tab says `PUBLIC_KEY: Denied`.** The key is only on the WSL side. See
install step 3.

**A command set on the SSH tab doesn't run.** With `multiplexing = 'None'`,
WezTerm ignores `args` on the spawn action. Set the command with
`default_prog` on the SSH domain instead, which is how this config does it.

**vim inserts `A`/`B` lines or stray spaces on arrow keys.** With no
`~/.vimrc`, vim was starting in vi-compatible mode, so arrow keys in insert
mode were read as Esc, `O`, then a letter. `set nocompatible` fixes it. A
previous `.vimrc` also had `imap` lines with trailing spaces before `|`. In
vim mappings those spaces become part of the replacement text, so they get
typed. Don't add arrow-key mappings; vim already recognizes the sequences.

**vim keys act oddly.** If vim misbehaves only in WezTerm, try
`enable_kitty_keyboard = false` in `wezterm.lua` to rule out the Kitty
keyboard protocol.

**Links don't open in Chrome.** If a toast says `Chrome not found`, none of
the three paths in `chrome_paths` exist on that machine — add yours. If
nothing happens at all on a click, the URL probably isn't `http(s)`; other
schemes are deliberately left to WezTerm's default handling.

**Ctrl+Shift+O opens the wrong URL, or garbles it.** It takes the first
`http(s)` match in the selection after deleting all whitespace, so a selection
containing two URLs resolves to whichever comes first, and a URL whose path
legitimately contains a space will be joined. Select just the URL.

**Don't nest herdr.** WezTerm splits of a toolsbox tab run `default_prog`
again and start herdr inside herdr. Split panes inside herdr itself instead
(Ctrl+B prefix).

## License

`wezterm/wezterm.sh` is vendored from the [wezterm
project](https://github.com/wezterm/wezterm) under its own MIT license. The
config and notes here are MIT as well.
