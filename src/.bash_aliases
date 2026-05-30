#!/usr/bin/env bash

alias cat="batcat"
alias ls="eza --icons --group-directories-first --group --header --git"

help() {
    "$@" --help 2>&1 | batcat --plain --language=help
}