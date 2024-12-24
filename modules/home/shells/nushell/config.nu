let fish_completer = {|spans|
fish --command $'complete "--do-complete=($spans | str join " ")"'
| $"value(char tab)description(char newline)" + $in
| from tsv --flexible --no-infer
}

let carapace_completer = {|spans|
carapace $spans.0 nushell $spans | from json
}

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

$env.config = {
show_banner: false,
menus: $menus,
keybindings: $keybindings

# completions: {
#   external: {
#     enable: true
#     completer: $fish_completer
#   }
# },

# completions: {
#   case_sensitive: false # case-sensitive completions
#   quick: true    # set to false to prevent auto-selecting completions
#   partial: true    # set to false to prevent partial filling of the prompt
#   algorithm: "fuzzy"    # prefix or fuzzy
#   external: {
#   # set to false to prevent nushell looking into $env.PATH to find more suggestions
#       enable: true 
#   # set to lower can improve completion performance at the cost of omitting some options
#       max_results: 100 
#       completer: $carapace_completer # check 'carapace_completer' 
#     }
#   }

# color_config: {
#   separator: "${base03}"
#   leading_trailing_space_bg: "${base04}"
#   header: "${base0B}"
#   date: "${base0E}"
#   filesize: "${base0D}"
#   row_index: "${base0C}"
#   bool: "${base08}"
#   int: "${base0B}"
#   duration: "${base08}"
#   range: "${base08}"
#   float: "${base08}"
#   string: "${base04}"
#   nothing: "${base08}"
#   binary: "${base08}"
#   cellpath: "${base08}"
#   hints: dark_gray

#   # base16 white on red
#   flatshape_garbage: { fg: "${base07}" bg: "${base08}" attr: b}
#   # if you like the regular white on red for parse errors:
#   # flatshape_garbage: { fg: "#FFFFFF" bg: "#FF0000" attr: b}
#   flatshape_bool: "${base0D}"
#   flatshape_int: { fg: "${base0E}" attr: b}
#   flatshape_float: { fg: "${base0E}" attr: b}
#   flatshape_range: { fg: "${base0A}" attr: b}
#   flatshape_internalcall: { fg: "${base0C}" attr: b}
#   flatshape_external: "${base0C}"
#   flatshape_externalarg: { fg: "${base0B}" attr: b}
#   flatshape_literal: "${base0D}"
#   flatshape_operator: "${base0A}"
#   flatshape_signature: { fg: "${base0B}" attr: b}
#   flatshape_string: "${base0B}"
#   flatshape_filepath: "${base0D}"
#   flatshape_globpattern: { fg: "${base0D}" attr: b}
#   flatshape_variable: "${base0E}"
#   flatshape_flag: { fg: "${base0D}" attr: b}
#   flatshape_custom: {attr: b}
# }
}
