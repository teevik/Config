# Source tool integrations
source ~/.cache/carapace/init.nu
source ~/.cache/zoxide.nu

let menus = []

let keybindings = [
  {
      name: fuzzy_file
      modifier: control
      keycode: char_t
      mode: emacs
      event: {
          send: executehostcommand
          cmd: "commandline edit --insert (fzf --layout=reverse)"
      }
  }
]

let history = {
    max_size: 100_000 # Session has to be reloaded for this to take effect
    sync_on_enter: true # Enable to share history between multiple sessions, else you have to close the session to write history to file
    file_format: "sqlite" # "sqlite" or "plaintext"
    isolation: true
}

$env.config = {
  show_banner: false
  menus: $menus
  keybindings: $keybindings
  history: $history
  use_kitty_protocol: true
  hooks: {
    pre_execution: [
      {|| $env.repl_commandline = (commandline) }
    ]
    pre_prompt: [
      {||
        let threshold_ms = 10000
        let duration_ms = ($env.CMD_DURATION_MS | into int)
        if $duration_ms > $threshold_ms {
          let duration_secs = ($duration_ms / 1000 | math round)
          let cmd = ($env.repl_commandline? | default "Command")
          notify-send "Command finished" $"($cmd) completed in ($duration_secs)s"
        }
      }
    ]
  }
}

# Direnv integration
$env.config.hooks.env_change = {
    PWD: [{||
        if (which direnv | is-empty) {
            return
        }
        direnv export json | from json | default {} | load-env
        if 'ENV_CONVERSIONS' in $env and 'PATH' in $env.ENV_CONVERSIONS {
            $env.PATH = do $env.ENV_CONVERSIONS.PATH.from_string $env.PATH
        }
    }]
}

alias zed = zeditor

$env.PROMPT_COMMAND = {||
  let path = ($env.PWD | str replace $env.HOME '~')
  let ssh_prefix = if ($env.SSH_CONNECTION? | is-not-empty) {
    let hostname = (hostname | str trim)
    $"(ansi magenta_bold)\(($hostname)\)(ansi reset) "
  } else {
    ""
  }
  $"($ssh_prefix)(ansi green)($path)(ansi reset)"
}

def with-clean-term [cmd: string, ...args] {
    kitty @ set-spacing padding=0
    kitty @ set-background-opacity 1

    try {
        ^$cmd ...$args
    }

    kitty @ set-spacing padding=default
    kitty @ set-background-opacity 0.5
}

def --wrapped hx [...args] { with-clean-term "hx" ...$args }
def --wrapped opencode [...args] { with-clean-term "opencode" ...$args }
def --wrapped nvim [...args] { with-clean-term "nvim" ...$args }

def --wrapped sudo [...args] {
    notify-send "Sudo" "Password may be required"
    ^sudo ...$args
}
