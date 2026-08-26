#!/bin/bash

# Usage: find-files-modified-in-hour <path> <filter>
# Example: find-files-modified-in-hour ~/Projects/django *.html

find-files-modified-in-hour() {
    local path="$1"
    local filter="$2"

    if [ $# -lt 2 ]; then
        echo "Usage: $0 <path> <filter>"
        echo "Example: $0 ~/Projects/django *.html"
        return 1
    fi

    find "$path" -type f -name "$filter" -mmin -60
}

find-files-modified-in-minutes() {
    local path="$1"
    local filter="$2"
    local minutes="${3:-0}"

    if [ $# -lt 2 ]; then
        echo "Usage: $0 <path> <filter> <minutes>"
        echo "Example: $0 ~/Projects/django *.html 30"
        return 1
    fi

    find "$path" -type f -name "$filter" -mmin -"$minutes"
}

find-files-older-than-days() {
    local path="$1"
    local filter="$2"
    local days="$3"

    if [ $# -lt 3 ]; then
        echo "Usage: $0 <path> <filter> <days>"
        echo "Example: $0 ~/Projects/django *.html 7"
        return 1
    fi

    find "$path" -type f -name "$filter" -mtime +"$days"
}

find-files-size-greater-than() {
    local path="$1"
    local filter="$2"
    local size="$3"

    if [ $# -lt 3 ]; then
        echo "Usage: $0 <path> <filter> <size>"
        echo "Example: $0 ~/Projects/django *.html 500k"
        return 1
    fi

    find "$path" -type f -name "$filter" -size +"$size"
}

find-files-size-smaller-than() {
    local path="$1"
    local filter="$2"
    local size="$3"

    if [ $# -lt 3 ]; then
        echo "Usage: $0 <path> <filter> <size>"
        echo "Example: $0 ~/Projects/django *.html 500k"
        return 1
    fi

    find "$path" -type f -name "$filter" -size -"$size"
}

find-files-with-permissions() {
    local path="$1"
    local filter="$2"
    local perms="$3"

    if [ $# -lt 3 ]; then
        echo "Usage: $0 <path> <filter> <permissions>"
        echo "Example: $0 ~/Projects/django *.html 644"
        return 1
    fi

    find "$path" -type f -name "$filter" -perm "$perms"
}

# Autocompletions for the script
_find-autocomplete() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts=$(compgen -A function | grep '^find-files-')

    if [[ ${prev} == "find-files-modified-in-hour" || ${prev} == "find-files-modified-in-minutes" || ${prev} == "find-files-older-than-days" || ${prev} == "find-files-size-greater-than" || ${prev} == "find-files-size-smaller-than" || ${prev} == "find-files-with-permissions" ]] ; then
        COMPREPLY=( $(compgen -o default -- "${cur}") )
        return 0
    fi

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _find-autocomplete find-files-modified-in-hour
complete -F _find-autocomplete find-files-modified-in-minutes
complete -F _find-autocomplete find-files-older-than-days
complete -F _find-autocomplete find-files-size-greater-than
complete -F _find-autocomplete find-files-size-smaller-than
complete -F _find-autocomplete find-files-with-permissions