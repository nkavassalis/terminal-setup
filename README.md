# terminal-setup

My terminal configuration: WezTerm on Windows 11 (driving WSL2 Ubuntu) today,
with Ghostty on macOS/Linux planned. Each subdirectory is a self-contained,
installable bundle with its own README — pick the one for your platform and
read that.

## Layout

```
terminal-setup/
├── README.md            This file
└── wezterm/             WezTerm on Windows 11 + WSL2 Ubuntu  -> wezterm/README.md
```

Planned, not written yet:

```
ghostty/                 Ghostty on macOS and Linux
```

Nothing under `ghostty/` exists yet. There is no config, no install script,
and no schedule for it — it's a note to self, not a promise.

## Bundles

### `wezterm/` — Windows 11 + WSL2

WezTerm as the outer terminal, WSL2 Ubuntu as the default shell, and a
one-key SSH connection to a remote box that drops straight into
[herdr](https://herdr.dev).

Includes the WezTerm Lua config, the vendored shell-integration script (so
installation needs no network fetch), and a small vim config for the remote
box. Install steps, key bindings, per-machine settings and a troubleshooting
section written from real setup failures are in
[`wezterm/README.md`](wezterm/README.md).

Highlights:

- Ctrl+Shift+T for a local tab in `~`, Ctrl+Shift+S for a tab on the remote box
- Windows Terminal-style paste, including Shift+right-click that works even
  when an app has captured the mouse
- Tab titles showing the running program or directory
- Kitty keyboard and graphics protocols enabled, so agents get Shift+Enter
  and image rendering

### `ghostty/` — macOS and Linux (TBD)

The intent is the same shape as `wezterm/`: config checked in, no remote
fetches at install time, per-machine values called out in one place, and the
troubleshooting notes that only come from actually living in the setup.

Open questions before any of that exists:

- How much of the WezTerm behavior is worth reproducing (the paste
  bindings, the tab-title scheme, the one-key SSH-into-herdr flow) versus
  leaning on Ghostty's defaults
- Whether the remote box needs the same shell-integration hook, and what the
  macOS/Linux equivalents of the Windows-side SSH key handling look like
- One config file shared across macOS and Linux with OS-conditional blocks,
  or two files

If you're reading this and `ghostty/` still isn't there, it just hasn't been
done yet.

## Conventions across bundles

- **Nothing is downloaded during install.** Anything third-party that the
  setup depends on is vendored into the bundle, with its upstream source
  named in that bundle's README.
- **No machine-specific values are checked in.** Hostnames, IP addresses,
  account names and home-directory paths are placeholders in the docs and
  called out as per-machine settings in the config.
- **No private keys.** Public keys aren't needed either.
- **Each bundle documents its own install.** The parent README is a map, not
  the instructions.

## License

MIT, except where a bundle's README says otherwise — vendored third-party
files stay under their own licenses.
