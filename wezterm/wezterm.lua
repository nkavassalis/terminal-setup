local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

----------------------------------------------------------------------
-- WSL
----------------------------------------------------------------------
config.wsl_domains = {
  {
    name = 'WSL:Ubuntu',
    distribution = 'Ubuntu',
    username = 'nick',
    default_cwd = '/home/nick',
  },
}
config.default_domain = 'WSL:Ubuntu'

-- One spawn action used by Ctrl+Shift+T and the + button
local spawn_home = act.SpawnCommandInNewTab {
  domain = { DomainName = 'WSL:Ubuntu' },
  cwd = '/home/nick',
}

----------------------------------------------------------------------
-- toolsbox (WezTerm's built-in SSH, bypasses WSL/ConPTY)
-- Uses keys/config from C:\Users\nick\.ssh, not WSL's ~/.ssh
----------------------------------------------------------------------
config.ssh_domains = {
  {
    name = 'toolsbox',
    remote_address = '10.1.13.35',
    username = 'nick',      -- change if your remote username differs
    multiplexing = 'None',  -- plain SSH; no wezterm needed on the remote
    -- With multiplexing = 'None', this is how you set the startup command.
    -- Starts herdr; detaching drops you to a normal login shell.
    default_prog = { 'bash', '-lc', '/home/nick/.local/bin/herdr; exec bash -l' },
    ssh_option = {
      -- Windows-side copy of your key
      identityfile = 'C:/Users/nick/.ssh/id_ed25519',
    },
  },
}

-- Open a tab on toolsbox (runs the domain's default_prog above)
local spawn_toolsbox = act.SpawnCommandInNewTab {
  domain = { DomainName = 'toolsbox' },
}

----------------------------------------------------------------------
-- Input
----------------------------------------------------------------------
-- Fixes odd key behavior in vim under ConPTY/WSL
config.allow_win32_input_mode = false

-- Lets Claude Code / Codex etc. see chords like Shift+Enter (helps herdr).
config.enable_kitty_keyboard = true

-- Lets herdr render images/graphics panes
config.enable_kitty_graphics = true

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
config.initial_cols = 160
config.initial_rows = 48

----------------------------------------------------------------------
-- Colors: Ubuntu aubergine (Windows Terminal's Ubuntu-ColorScheme)
----------------------------------------------------------------------
config.color_schemes = {
  ['Ubuntu WT'] = {
    background = '#300A24',
    foreground = '#EEEEEC',
    cursor_bg = '#EEEEEC',
    cursor_border = '#EEEEEC',
    cursor_fg = '#300A24',
    selection_bg = '#EEEEEC',
    selection_fg = '#300A24',
    ansi = {
      '#171421', '#C01C28', '#26A269', '#A2734C',
      '#12488B', '#A347BA', '#2AA1B3', '#D0CFCC',
    },
    brights = {
      '#5E5C64', '#F66151', '#33DA7A', '#E9AD0C',
      '#2A7BDE', '#C061CB', '#33C7DE', '#FFFFFF',
    },
  },
}
config.color_scheme = 'Ubuntu WT'

-- Optional: same font as Windows Terminal
-- config.font = wezterm.font 'Cascadia Mono'
-- config.font_size = 11

----------------------------------------------------------------------
-- Links: open http(s) URLs in Chrome instead of the default browser
----------------------------------------------------------------------
local chrome_paths = {
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
  (os.getenv('LOCALAPPDATA') or '') .. '\\Google\\Chrome\\Application\\chrome.exe',
}

local function find_chrome()
  for _, p in ipairs(chrome_paths) do
    local f = io.open(p, 'r')
    if f then
      f:close()
      return p
    end
  end
end

local chrome = find_chrome()

local function open_in_chrome(uri)
  if chrome then
    -- Add '--profile-directory=Profile 1' before uri to pick a profile
    wezterm.background_child_process { chrome, uri }
    return true
  end
  return false
end

-- Single-line links clicked directly (Shift+click inside herdr).
-- Non-web schemes (mailto:, file:, ...) fall through to the default.
wezterm.on('open-uri', function(window, pane, uri)
  if uri:match('^https?://') and open_in_chrome(uri) then
    return false
  end
end)

-- Rebuild a wrapped URL from the current selection (or the clipboard)
-- and open it in Chrome. Bound to Ctrl+Shift+O below.
local function open_selected_url(window, pane)
  local text = window:get_selection_text_for_pane(pane)

  -- No WezTerm selection? Fall back to the Windows clipboard
  -- (e.g. something copied in herdr's copy mode via OSC 52).
  if text == nil or text == '' then
    local ok, out = wezterm.run_child_process {
      'powershell.exe', '-NoProfile', '-Command', 'Get-Clipboard -Raw',
    }
    text = (ok and out) or ''
  end

  -- Drop box-drawing characters (pane borders, U+2500 to U+257F)
  text = text:gsub(utf8.charpattern, function(c)
    local ok, cp = pcall(utf8.codepoint, c)
    if ok and cp >= 0x2500 and cp <= 0x257F then
      return ''
    end
  end)

  -- Join the wrapped pieces back together
  text = text:gsub('%s+', '')

  local url = text:match('https?://[^"\'<>`]+')
  if url and open_in_chrome(url) then
    window:perform_action(act.ClearSelection, pane)
  elseif not chrome then
    window:toast_notification('WezTerm', 'Chrome not found', nil, 3000)
  else
    window:toast_notification('WezTerm', 'No URL found in selection', nil, 3000)
  end
end

----------------------------------------------------------------------
-- Keys (WezTerm defaults like Ctrl+Shift+V paste still apply)
----------------------------------------------------------------------
config.keys = {
  -- New local tab, always in ~
  { key = 't', mods = 'CTRL|SHIFT', action = spawn_home },

  -- New tab on toolsbox, straight into herdr
  { key = 's', mods = 'CTRL|SHIFT', action = spawn_toolsbox },

  -- Open the selected (possibly wrapped) URL in Chrome
  { key = 'o', mods = 'CTRL|SHIFT', action = wezterm.action_callback(open_selected_url) },

  -- Windows Terminal-style Ctrl+V paste
  -- (vim's visual block moves to Ctrl+Q)
  { key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },
}

----------------------------------------------------------------------
-- Mouse
----------------------------------------------------------------------
config.mouse_bindings = {
  -- Right-click pastes when no app is capturing the mouse
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = act.PasteFrom 'Clipboard',
  },
  -- Shift+right-click pastes even inside herdr/vim (bypasses mouse capture)
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'SHIFT',
    action = act.PasteFrom 'Clipboard',
  },
}

----------------------------------------------------------------------
-- + button: left-click opens a local tab in ~, right-click keeps the
-- launcher menu (which also lists the 'toolsbox' SSH domain)
----------------------------------------------------------------------
wezterm.on('new-tab-button-click', function(window, pane, button, default_action)
  if button == 'Left' then
    window:perform_action(spawn_home, pane)
    return false
  end
end)

----------------------------------------------------------------------
-- Window title: "[2/3] WezTerm" instead of "wslhost.exe"
----------------------------------------------------------------------
wezterm.on('format-window-title', function(tab, pane, tabs)
  local idx = ''
  if #tabs > 1 then
    idx = string.format('[%d/%d] ', tab.tab_index + 1, #tabs)
  end
  return idx .. 'WezTerm'
end)

----------------------------------------------------------------------
-- Tab titles: running program if any, else cwd basename
-- (requires wezterm.sh shell integration sourced in ~/.bashrc)
----------------------------------------------------------------------
local function basename(s)
  return (s:gsub('[/\\]+$', '')):match('([^/\\]+)$') or s
end

wezterm.on('format-tab-title', function(tab)
  local pane = tab.active_pane
  local prog = pane.user_vars.WEZTERM_PROG
  local title

  if prog and prog ~= '' then
    title = prog
  else
    local cwd = pane.current_working_dir
    if cwd then
      local path = type(cwd) == 'userdata' and cwd.file_path or tostring(cwd)
      if path:match('^/home/nick/?$') then
        title = '~'
      else
        title = basename(path)
      end
    else
      title = pane.title
    end
  end

  -- Label remote tabs so they're easy to tell apart
  if pane.domain_name == 'toolsbox' then
    if title == '' or title == 'wslhost.exe' or title == 'wsl.exe' or title == 'wezterm' then
      title = 'herdr'
    end
    return ' ' .. (tab.tab_index + 1) .. ': [toolsbox] ' .. title .. ' '
  end

  if title == 'wslhost.exe' or title == 'wsl.exe' or title == '' then
    title = 'Ubuntu'
  end
  return ' ' .. (tab.tab_index + 1) .. ': ' .. title .. ' '
end)

return config
