# Disable greeting
set fish_greeting

# Keybindings
bind \b backward-kill-word
bind \e\[3\;5~ kill-word

# Environment variables
set -gx EDITOR hx

# Tool integrations
zoxide init fish | source
fzf --fish | source
carapace _carapace fish | source
direnv hook fish | source

# Yazi shell integration
function ya
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end
