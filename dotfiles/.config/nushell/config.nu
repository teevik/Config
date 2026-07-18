# Source tool integrations
# source ~/.cache/zoxide.nu
# source ~/.cache/worktrunk-init.nu

# Plugins
plugin use skim

# Scripts from nu_scripts
use /etc/nushell/scripts/ultimate_extractor.nu *

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

# External completions
# Load Carapace after assigning $env.config so its completer is not overwritten.
source ~/.cache/carapace/init.nu

let carapace_completer = $env.config.completions.external.completer

# Fish has especially good completions for git and fills gaps in Carapace's
# command coverage. Convert Fish's escaped paths to syntax Nushell accepts.
let fish_completer = {|spans: list<string>|
    fish --no-config --command $"complete '--do-complete=($spans | str replace --all "'" "\\'" | str join ' ')'"
    | from tsv --flexible --noheaders --no-infer
    | rename value description
    | update value {|row|
        let value = $row.value
        let needs_quote = ['\\' ',' '[' ']' '(' ')' ' ' '\t' "'" '"' '`'] | any { $in in $value }

        if ($needs_quote and ($value | path exists)) {
            let expanded_path = if ($value starts-with '~') {
                $value | path expand --no-symlink
            } else {
                $value
            }
            $'"($expanded_path | str replace --all '"' '\\"')"'
        } else {
            $value
        }
    }
}

let external_completer = {|spans: list<string>|
    # External completers see the alias name, so expand its first command.
    let expanded_alias = scope aliases
        | where name == $spans.0
        | get -o 0.expansion
    let spans = if $expanded_alias != null {
        $spans
        | skip 1
        | prepend ($expanded_alias | split row ' ' | take 1)
    } else {
        $spans
    }

    match $spans.0 {
        # Fish is more accurate for Nushell itself and git refs.
        nu | git | asdf => $fish_completer
        _ => $carapace_completer
    } | do $in $spans
}

$env.config.completions.external = {
    enable: true
    max_results: 100
    completer: $external_completer
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

# Devenv auto-activation
# Enable this after updating to a devenv release that includes the Nushell hook fixes.
# mkdir ~/.cache/devenv
# devenv hook nu | save --force ~/.cache/devenv/hook.nu
# source ~/.cache/devenv/hook.nu

alias zed = zeditor
alias neofetch = fastfetch

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
    let kitty_socket = $env.KITTY_LISTEN_ON?
    let kitty_available = if ($kitty_socket | is-empty) {
        false
    } else {
        try {
            kitty @ ls o+e> /dev/null
            true
        } catch {
            false
        }
    }

    if not $kitty_available {
        ^$cmd ...$args
        return
    }

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
