# let fish_completer = {|spans|
#   fish --command $'complete "--do-complete=($spans | str join " ")"'
#     | $"value(char tab)description(char newline)" + $in
#     | from tsv --flexible --no-infer
# }

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
    isolation: false
}

$env.config = {
  show_banner: false
  menus: $menus
  keybindings: $keybindings
  history: $history
}
