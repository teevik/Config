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
}

alias zed = zeditor

def with-clean-term [cmd: string, ...args] {
    kitty @ set-spacing padding=0
    kitty @ set-background-opacity 1

    try {
        ^$cmd ...$args
    }

    kitty @ set-spacing padding=default  
    kitty @ set-background-opacity 0.5
}

def --wrapped opencode [...args] { with-clean-term "opencode" ...$args }
def --wrapped nvim [...args] { with-clean-term "nvim" ...$args }
