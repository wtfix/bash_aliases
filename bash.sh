#!/bin/bash

shopt -s globstar
shopt -s dotglob

# bind requires readline (interactive shells only)
if [[ $- == *i* ]]; then
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
fi

alias history-off='set +o history'
alias history-on='set -o history'

# Enable appending to the history file instead of overwriting it
shopt -s histappend

# Set the PROMPT_COMMAND to execute commands before displaying the prompt
# - history -a: Appends the current session's history to the history file
# - history -n: Reads any new commands from the history file into the current session
export PROMPT_COMMAND="history -a; history -n"

export HISTSIZE=10000      # Number of commands kept in memory
export HISTFILESIZE=20000  # Number of commands kept in the history file

# Avoid saving duplicate commands in history
# export HISTCONTROL=ignoredups:erasedups

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

mkdircd ()
{ 
    mkdir -p "$1" && cd "$1"
}

alias rh='rehash'
