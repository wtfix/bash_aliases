#!/bin/bash

# List all files except dots and display size in human readable format
alias ll="ls -lAh"

alias llast="ll -ltr"
alias list-all-and-sort-by-modify-date="llast"

# Sort files by size. For dirs see 'dutop'
alias lltop="ll -S"
alias list-all-and-sort-files-by-size="llast"

# List only directories in the specified path or current directory
lldir() {
    # If no argument is provided, use the current directory
    local dir="${1:-.}"
    find "$dir" -maxdepth 1 -type d | sed 's:/*$::'
}
alias list-dirs-only="lldir"

# List only files in the specified path or current directory
llfile() {
    # If no argument is provided, use the current directory
    local dir="${1:-.}"
    find "$dir" -maxdepth 1 -type f
}
alias list-files-only="llfile"


# List only symlinks in the specified path or current directory
lllink() {
    # If no argument is provided, use the current directory
    local dir="${1:-.}"
    find "$dir" -maxdepth 1 -type l
}
alias list-links-only="lllink"

# List only hidden files in the specified path or current directory
llhidden() {
    # If no argument is provided, use the current directory
    local dir="${1:-.}"
    find "$dir" -maxdepth 1 -name ".*" -type f
}
alias list-hidden-files-only="llhidden"

# List only hidden directories in the specified path or current directory
llhdir() {
    # If no argument is provided, use the current directory
    local dir="${1:-.}"
    find "$dir" -maxdepth 1 -name ".*" -type d
}
alias list-hidden-dirs-only="llhdir"

# List only hidden symlinks in the specified path or current directory
llhlink() {
    # If no argument is provided, use the current directory
    local dir="${1:-.}"
    find "$dir" -maxdepth 1 -name ".*" -type l
}
alias list-hidden-links-only="llhlink"

# List only hidden files and directories in the specified path or current directory
llh() {
    # If no argument is provided, use the current directory
    local dir="${1:-.}"
    find "$dir" -maxdepth 1 -name ".*"
}
alias list-hidden-only="llh"

alias grep='grep -d skip --color=auto'

alias trees='tree -a -I ".venv|.ruff_cache|.idea|.git|__pycache__|node_modules|.next|*.egg-info|alembic" -F'


batf() {
    local pattern="$1"
    local search_path="${2:-.}"
    local file

    # Uses standard find and safely strips out dependencies via grep
    file=$(find "$search_path" -type f -name "$pattern" 2>/dev/null | \
        grep -vE '/(node_modules|\.venv|\.git)/' | \
        fzf --height 40% --layout=reverse --border --select-1)

    if [ -n "$file" ]; then
        bat "$file"
    fi
}

slice() {
    # Replace hyphen with a comma for sed
    local range=$(echo "$1" | tr '-' ',')

    # Check if a file argument is provided and exists
    if [ -n "$2" ] && [ -f "$2" ]; then
        sed -n "${range}p" "$2"
    else
        # Read from standard input (stdin) if no file is given
        sed -n "${range}p"
    fi
}


CATFILES_COMMON_EXCLUDE_PATTERNS=(
    .venv
    .ruff_cache
    .idea
    .git
    __pycache__
    node_modules
    .next
    '*.egg-info'
)

catfiles() {
    local -a exclude_patterns=()
    local arg use_common=0

    # ---------- Option parsing ----------
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -e|--exclude)
                [[ -z "$2" ]] && { echo "Error: $1 requires a pattern" >&2; return 1; }
                exclude_patterns+=("$2")
                shift 2
                ;;
            -c|--common)
                use_common=1
                shift
                ;;
            -h|--help)
                cat <<'EOF'
Usage: catfiles [OPTIONS] PATH...

Print files with clear separators.

Options:
  -e, --exclude PATTERN   Exclude files/directories matching PATTERN.
                          PATTERN can be a name (e.g. .git) or a glob
                          (e.g. *.log). May be used multiple times.
  -c, --common            Exclude a predefined list of common directories
                          and files (see CATFILES_COMMON_EXCLUDE_PATTERNS
                          above). Can be combined with additional -e.
  -h, --help              Show this help message.
  --                      End of options.
EOF
                return 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                echo "Unknown option: $1" >&2
                return 1
                ;;
            *)
                break
                ;;
        esac
    done

    # Append common patterns if requested
    if (( use_common )); then
        exclude_patterns+=("${CATFILES_COMMON_EXCLUDE_PATTERNS[@]}")
    fi

    print_file() {
        local file="$1"
        printf -- '<<<FILE_START>>>\nFile: %s\n' "$file"
        cat -- "$file"
        printf '<<<FILE_END>>>\n\n'
    }

    # Build find expression
    local -a find_expr=()
    if (( ${#exclude_patterns[@]} > 0 )); then
        find_expr+=( '(' )
        for i in "${!exclude_patterns[@]}"; do
            local pattern="${exclude_patterns[$i]}"
            if [[ "$pattern" != */* ]]; then
                find_expr+=( -path "*/$pattern" -o -path "*/$pattern/*" -o -path "$pattern" -o -path "$pattern/*" )
            else
                find_expr+=( -path "$pattern" -o -path "$pattern/*" )
            fi
            (( i < ${#exclude_patterns[@]} - 1 )) && find_expr+=( -o )
        done
        find_expr+=( ')' -prune -o -type f )
    else
        find_expr+=( -type f )
    fi

    # Process remaining arguments
    for arg in "$@"; do
        if [[ -f "$arg" ]]; then
            print_file "$arg"
        elif [[ -d "$arg" ]]; then
            while IFS= read -r -d '' file; do
                print_file "$file"
            done < <(find "$arg" "${find_expr[@]}" -print0 | sort -z)
        else
            echo "Warning: '$arg' is not a file or directory – skipping" >&2
        fi
    done
}

