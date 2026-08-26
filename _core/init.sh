#!/bin/bash

if [ -z "$BASH_ALIASES_ROOT" ]; then
    if [ -d "$HOME/bash_aliases" ]; then
        export BASH_ALIASES_ROOT="$HOME/bash_aliases"
    else
        echo "Warning: $HOME/bash_aliases directory not found."
        potential_dirs=("/etc/bash_aliases" "$HOME/.bash_aliases" "/root/bash_aliases")
        for dir in "${potential_dirs[@]}"; do
            if [ -d "$dir" ]; then
                echo "Found bash_aliases directory at $dir"
                export BASH_ALIASES_ROOT="$dir"
                break
            fi
        done
        if [ -z "$BASH_ALIASES_ROOT" ]; then
            echo "Error: Unable to find bash_aliases directory."
            return 1
        fi
    fi
fi

# Enable the globstar option for recursive globbing
shopt -s globstar

export BASH_ALIASES_SRC="$BASH_ALIASES_ROOT/_core"

# Array to keep track of sourced files to avoid circular references
declare -A sourced_files

# Add our $BASH_SOURCE to the sourced_files array
sourced_files["$BASH_SOURCE"]=1

# Function to source files safely
source_file() {
    local file="$1"
    if [[ -f "$file" && -z "${sourced_files[$file]}" ]]; then
        source "$file" || { echo "Failed to source $file" >&2; return 1; }
        sourced_files["$file"]=1  # Mark this file as sourced
    fi
}

# Source configuration and core functions
export BASH_ALIASES_CONFIG_FILE="$BASH_ALIASES_ROOT/_config.sh"
# source_file "$BASH_ALIASES_ROOT/_core.sh"
# source_file "$BASH_ALIASES_ROOT/_helpers.sh"
source_file "$BASH_ALIASES_CONFIG_FILE"
source_file "$BASH_ALIASES_SRC/editor.sh"
source_file "$BASH_ALIASES_SRC/config.sh"
source_file "$BASH_ALIASES_SRC/functions.sh"
source_file "$BASH_ALIASES_SRC/presets.sh"
__ba_preset_load


# Initialize counter
total_files=0

# Source alias scripts; root-level categories are filtered by .preset,
# sub-directories and _core are always active.
for file in "$BASH_ALIASES_ROOT"/**/*.sh; do
    [[ -e "$file" ]] || continue
    [[ "${file##*/}" == "install.sh" ]] && continue
    if [[ "${file#$BASH_ALIASES_ROOT/}" != */* ]] \
       && ! __ba_preset_allows "$(basename "${file%.sh}")"; then
        continue
    fi
    source_file "$file"
    ((total_files++))
done


rehash_aliases() {
    # Clear the sourced_files array
    unset sourced_files
    declare -A sourced_files

    # Re-source .bashrc
    source ~/.bashrc

    echo "Total bash alias files sourced: $total_files"
}

# Replace the existing rehash alias with this new function
alias rehash='rehash_aliases'

# alias rehash='source ~/.bashrc'