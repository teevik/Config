# Optional tool integrations
# source ~/.cache/worktrunk-init.nu

# Plugins
plugin use skim

# Scripts from nu_scripts
use /etc/nushell/scripts/ultimate_extractor.nu *
use /etc/nushell/scripts/completions.nu *

def current-project-root [] {
    let git_root = (^git rev-parse --show-toplevel | complete)

    if $git_root.exit_code == 0 {
        $git_root.stdout | str trim | path expand
    } else {
        $env.PWD | path expand
    }
}

def --env ensure-project-index [] {
    let root = (current-project-root)
    let status = (idx status)
    let indexed_root = ($status.base_path? | default "")

    if (not $status.initialized) or (($indexed_root | path expand) != $root) {
        idx init $root --wait | ignore
    }

    $root
}

def --env index-project [path: directory = .] {
    idx init ($path | path expand) --wait
}

def --env insert-fuzzy-file [] {
    ensure-project-index | ignore

    let selected = (
        idx files
        | sk --format relative_path --height "40%" --reverse
        | get -o 0.full_path
    )

    if $selected != null {
        commandline edit --insert ($selected | to nuon)
    }
}

let menus = []

let keybindings = []

let history = {
    max_size: 100_000 # Session has to be reloaded for this to take effect
    sync_on_enter: true # Enable to share history between multiple sessions, else you have to close the session to write history to file
    file_format: "sqlite" # "sqlite" or "plaintext"
    isolation: true
}

$env.config = {
  show_banner: false
  auto_cd_implicit: true
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

# FZF wraps the external completer above and adds Ctrl-R, Alt-C, and **<Tab>.
# Its static Ctrl-T binding is replaced below with a context-aware picker.
source /etc/nushell/scripts/fzf.nu
source /etc/nushell/scripts/zoxide.nu
source /etc/nushell/scripts/intelli-shell.nu

def smart-fzf-token-span [line: string, cursor: int, completions: list<any>] {
    let completion_span = ($completions | get -o 0.span)

    if $completion_span != null {
        {
            start: $completion_span.start
            end: $completion_span.end
            token: ($line | str substring $completion_span.start..<$completion_span.end)
        }
    } else {
        let before_cursor = ($line | str substring 0..<$cursor)
        let token = (
            $before_cursor
            | parse --regex '(?<token>\S*)$'
            | get -o 0.token
            | default ""
        )

        {
            start: ($cursor - ($token | str length))
            end: $cursor
            token: $token
        }
    }
}

def smart-fzf-path-context [token: string] {
    let token = ($token | str trim -c '"' | str trim -c "'")
    let has_separator = ($token | str contains (char separator))
    let ends_with_separator = ($token | str ends-with (char separator))

    let context = if $ends_with_separator and ($token | path expand | path type) == dir {
        { root: $token, query: "" }
    } else if $has_separator {
        let root = ($token | path dirname)
        let valid_root = if ($root | is-not-empty) and ($root | path expand | path type) == dir {
            $root
        } else {
            "."
        }
        { root: $valid_root, query: ($token | path basename) }
    } else {
        { root: ".", query: $token }
    }

    {
        root: (if ($context.root | str starts-with '~') { $context.root | path expand } else { $context.root })
        query: $context.query
        restore_tilde: ($token | str starts-with '~')
    }
}

def smart-fzf-quote-path [path: string] {
    let needs_quote = ['\\' ',' '[' ']' '(' ')' ' ' '\t' "'" '"' '`']
        | any {|character| $path | str contains $character }

    if $needs_quote { $path | to nuon } else { $path }
}

def smart-fzf-run-semantic [completions: list<any>, query: string] {
    let candidates = (
        $completions
        | enumerate
        | each {|row|
            let description = (
                $row.item.description?
                | default ""
                | str replace --all (char tab) " "
                | str replace --all (char newline) " "
            )
            $"($row.index)(char tab)($row.item.value)(char tab)($description)"
        }
        | str join (char newline)
    )
    let fzf_opts = (__fzf_defaults '--reverse --scheme=default' $'($env.FZF_CTRL_T_OPTS) +m')
    let fzfcmd = (__fzfcmd)
    let fzf_args = ($fzfcmd | skip 1)
    let selected = try {
        $candidates
        | with-env { FZF_DEFAULT_OPTS: $fzf_opts, FZF_DEFAULT_OPTS_FILE: "" } {
            ^($fzfcmd | first) ...$fzf_args --delimiter (char tab) --with-nth '2,3' --query $query
        }
        | str trim
    } catch {
        ""
    }

    if ($selected | is-empty) {
        null
    } else {
        let selected_index = ($selected | split row (char tab) | first | into int)
        $completions | get -o $selected_index
    }
}

def smart-fzf-run-paths [context: record, directories_only: bool] {
    let walker = if $directories_only { 'dir,follow,hidden' } else { 'file,dir,follow,hidden' }
    let multi = if $directories_only { '+m' } else { '-m' }
    let fzf_opts = (
        __fzf_defaults
        $'--reverse --walker=($walker) --scheme=path'
        $'($env.FZF_CTRL_T_OPTS) ($multi)'
    )
    let fzfcmd = (__fzfcmd)
    let fzf_args = ($fzfcmd | skip 1)

    try {
        with-env { FZF_DEFAULT_OPTS: $fzf_opts, FZF_DEFAULT_OPTS_FILE: "" } {
            ^($fzfcmd | first) ...$fzf_args --walker-root $context.root --query $context.query
        }
        | lines
        | where { $in | is-not-empty }
    } catch {
        []
    }
}

def --env smart-fzf-complete [] {
    let line = (commandline)
    let cursor = (commandline get-cursor)
    let before_cursor = ($line | str substring 0..<$cursor)
    let active_command = ($before_cursor | split row --regex '[;\n]' | last | str trim)
    let is_cd = ($active_command =~ '^cd(?:\s|$)')
    let cd_needs_space = $is_cd and ($active_command == 'cd') and not ($before_cursor | str ends-with ' ')
    let completions = try { commandline complete --detailed } catch { [] }
    let semantic_completions = if (not $is_cd) and ($active_command =~ '\s') {
        $completions | where {|item| ($item.kind? | default "") not-in [file directory] }
    } else {
        []
    }

    if ($semantic_completions | is-not-empty) {
        let span = (smart-fzf-token-span $line $cursor $semantic_completions)
        let selected = (smart-fzf-run-semantic $semantic_completions $span.token)

        if $selected != null {
            let replacement = $selected.value
            let updated = (
                ($line | str substring 0..<$selected.span.start)
                + $replacement
                + ($line | str substring $selected.span.end..)
            )
            commandline edit --replace $updated
            commandline set-cursor ($selected.span.start + ($replacement | str length))
        }
        return
    }

    let span = if $cd_needs_space {
        { start: $cursor, end: $cursor, token: "" }
    } else {
        smart-fzf-token-span $line $cursor $completions
    }
    let path_context = (smart-fzf-path-context $span.token)
    let selected_paths = (smart-fzf-run-paths $path_context $is_cd)

    if ($selected_paths | is-empty) {
        return
    }

    let home = ($nu.home-dir | path expand)
    let replacement = (
        $selected_paths
        | each {|path|
            let path = if $path_context.restore_tilde { $path | str replace $home '~' } else { $path }
            smart-fzf-quote-path $path
        }
        | str join ' '
    )
    let replacement = if $cd_needs_space { $" ($replacement)" } else { $replacement }
    let updated = (
        ($line | str substring 0..<$span.start)
        + $replacement
        + ($line | str substring $span.end..)
    )
    commandline edit --replace $updated
    commandline set-cursor ($span.start + ($replacement | str length))
}

let smart_ctrl_t = {
    name: fzf_files
    modifier: control
    keycode: char_t
    mode: [emacs vi_normal vi_insert]
    event: {
        send: executehostcommand
        cmd: "smart-fzf-complete"
    }
}

$env.config.keybindings = (
    $env.config.keybindings
    | where name != fzf_files
    | append $smart_ctrl_t
)

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

def slow [since: duration = 1wk] {
    history
    | where duration != null
    | where start_timestamp > ((date now) - $since)
    | sort-by duration --reverse
    | first 20
    | select start_timestamp duration exit_status command cwd
}

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

@complete external
def --wrapped hx [...args] { with-clean-term "hx" ...$args }

@complete external
def --wrapped opencode [...args] { with-clean-term "opencode" ...$args }

@complete external
def --wrapped opencode2 [...args] { with-clean-term "opencode2" ...$args }

@complete external
def --wrapped nvim [...args] { with-clean-term "nvim" ...$args }

@complete external
def --wrapped sudo [...args] {
    notify-send "Sudo" "Password may be required"
    ^sudo ...$args
}
