#!/bin/bash
# Project management

# Function to create a new project
function projects-new() {
    if [ -z "$1" ]; then
        echo "Error: No project name provided."
        return 1
    fi
    
    mkdir -p "$PROJECTS_DIR/$1"
    cd "$PROJECTS_DIR/$1" || return
}


# Define the path variable
PROJECTS_DIR=~/Projects

# Function to change directory to a subdirectory of the specified parameter
function projects() {
    if [ -z "$1" ]; then
        # If no argument is provided, just cd to the main projects directory
        cd "$PROJECTS_DIR" || return
    else
        # Check if the subdirectory exists
        if [ -d "$PROJECTS_DIR/$1" ]; then
            cd "$PROJECTS_DIR/$1" || return
        else
            echo "Directory '$1' does not exist in $PROJECTS_DIR."
        fi
    fi
}
alias proj="projects"
alias projn="projects-new"
projnv() {
    echo "Proj: $1"
    projects-new $1
    venv
}

# Autocompletion for the projects function
_projects_completion() {
    local cur dir
    cur="${COMP_WORDS[COMP_CWORD]}"
    dir="$PROJECTS_DIR"

    mapfile -t COMPREPLY < <(
        compgen -d -- "$dir/$cur" | sed "s#^$dir/##"
    )
}

complete -o filenames -F _projects_completion projects proj

# Function to list projects
function projects-ls() {
    ls -l "$PROJECTS_DIR"
}
