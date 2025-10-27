#!/usr/bin/env fish

set -gx EDITOR "micro"
set -gx LANG "en_US.UTF-8"
set -gx TZ "America/Lima"

set -gx LESSOPEN "|/usr/local/bin/lesspipe.sh %s"

set -U fish_greeting

# Add ~/bin to PATH if it exists
if test -d "$HOME/bin"
    fish_add_path -gP "$HOME/bin"
end

# Add ~/.local/bin to PATH if it exists
if test -d "$HOME/.local/bin"
    fish_add_path -gP "$HOME/.local/bin"
end

if status is-interactive
    mise activate fish | source
else
    mise activate fish --shims | source
end

rg --generate complete-fish | source
starship init fish | source

alias cat="batcat"
alias ls="eza --icons --group-directories-first --group --header --git"

abbr -a --position anywhere -- --help "--help | batcat -plhelp"
abbr -a --position anywhere -- -h "-h | batcat -plhelp"