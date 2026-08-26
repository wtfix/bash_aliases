#!/bin/bash

# ------------------------------------------------------------------
# aliases - the main command dispatcher
# ------------------------------------------------------------------
aliases() {
    local cmd="${1:-help}"
    shift 2>/dev/null

    case "$cmd" in
        l | list)                   aliases_list "$@" ;;
        s | search | f | find)      aliases_search "$@" ;;
        a | add | n | new | +)      aliases_add "$@" ;;
        r | remove | d | delete)    aliases_remove "$@" ;;
        e | edit | create)          aliases_edit "$@" ;;
        m | move)                   aliases_move "$@" ;;
        t | tree)                   aliases_tree "$@" ;;
        c | config)                 aliases_config "$@" ;;
        i | install)                aliases_install "$@" ;;
        w | which)                  aliases_which "$@" ;;
        sv | save-to-git | sync)    aliases_save_git "$@" ;;
        h | help | wtf)             aliases_help ;;
        *)                          echo "Unknown command: $cmd" >&2; aliases_help ;;
    esac
}

alias al="aliases"

# Commit all changes in $BASH_ALIASES_ROOT and push them to origin.
# Optional argument is used as the commit message.
aliases_save_git() {
    local msg="${*:-Update aliases}"

    command -v git >/dev/null 2>&1 || { echo "Error: git is not installed." >&2; return 1; }
    [[ -d "$BASH_ALIASES_ROOT/.git" ]] || { echo "Error: $BASH_ALIASES_ROOT is not a git repository." >&2; return 1; }

    cd "$BASH_ALIASES_ROOT" || return 1

    if [[ -z "$(git status --porcelain)" ]]; then
        echo "Working tree clean - nothing to save."
        return 0
    fi

    echo "Changes:"
    git status --short
    git add -A
    git commit -m "$msg" || { echo "Commit failed." >&2; return 1; }

    if git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
        git pull --rebase || { echo "Rebase against origin failed - resolve conflicts and push manually." >&2; return 1; }
    fi

    if git push; then
        echo "Saved & pushed: $msg"
    else
        echo "Push failed - set up push credentials for this host (SSH key or token)." >&2
        return 1
    fi
}

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

# Resolve a file argument to an absolute path under $BASH_ALIASES_ROOT.
# A category is a .sh file at the root; deeper groupings use sub-directories.
# The whole token gets ".sh" appended, so any depth works:
#   net                    -> $ROOT/net.sh
#   net/some               -> $ROOT/net/some.sh
#   net/some/deep          -> $ROOT/net/some/deep.sh
__bash_aliases_resolve_file() {
    local input="$1"
    printf '%s/%s.sh\n' "$BASH_ALIASES_ROOT" "${input%.sh}"
}

# Quote a string so it is safe between single quotes.
__bash_aliases_squote() {
    local s="$1"
    printf "'%s'" "${s//\'/\'\\\'\'}"
}

# Run the configured syntax-highlighting command on stdin.
# Uses $BASH_ALIASES_HIGHLIGHT_CMD when its binary exists, else plain `cat`.
__bash_aliases_run_highlighter() {
    local cmd="${BASH_ALIASES_HIGHLIGHT_CMD:-}"
    if [[ -n "$cmd" ]]; then
        local bin="${cmd%% *}"
        if command -v "$bin" >/dev/null 2>&1; then
            eval "$cmd"
            return
        fi
    fi
    cat
}

# Highlight a bash code snippet. For glow we wrap it in a ```bash fence so it
# gets proper bash syntax highlighting; other renderers get the raw text.
__bash_aliases_highlight() {
    local cmd="${BASH_ALIASES_HIGHLIGHT_CMD:-}"
    if [[ "$cmd" == glow* ]]; then
        printf '```bash\n%s\n```\n' "$1" | __bash_aliases_run_highlighter
    else
        printf '%s\n' "$1" | __bash_aliases_run_highlighter
    fi
}

# Extract a function definition (name + balanced body) from a file.
# Prints nothing if the name is not a function definition in that file.
__bash_aliases_extract_function() {
    local file="$1" name="$2" esc="$name"
    # Escape regex metacharacters in the function name.
    local i c
    esc=""
    for (( i=0; i<${#name}; i++ )); do
        c="${name:$i:1}"
        case "$c" in
            [a-zA-Z0-9_]) esc+="$c" ;;
            *) esc+="\\$c" ;;
        esac
    done
    awk -v fn="$esc" '
        function cb(s,   i, ch, d) { d=0; for (i=1; i<=length(s); i++){ ch=substr(s,i,1); if(ch=="{")d++; else if(ch=="}")d-- } return d }
        BEGIN { pat = "^[[:space:]]*(function[[:space:]]+)?" fn "[[:space:]]*\\(\\)" }
        $0 ~ pat {
            if (cap) next
            cap=1; depth=cb($0); if (depth>0) opened=1
            print $0
            if (opened && depth<=0) { cap=0; exit }
            next
        }
        cap {
            depth+=cb($0); if (depth>0) opened=1
            print $0
            if (opened && depth<=0) exit
        }
    ' "$file"
}

# Find a function by name anywhere under the aliases root.
# On success prints "REL:LINE" on the first line, then the definition body.
__bash_aliases_find_function() {
    local name="$1" file rel out ln
    shopt -s globstar
    for file in "$BASH_ALIASES_ROOT"/**/*.sh; do
        [[ -f "$file" && "$file" != */_core/* ]] || continue
        out="$(__bash_aliases_extract_function "$file" "$name")"
        if [[ -n "$out" ]]; then
            rel="${file#$BASH_ALIASES_ROOT/}"
            ln=$(grep -nE "^\s*(function\s+)?$name\s*\(\).*\{?" "$file" | head -n1 | cut -d: -f1)
            printf '%s:%s\n%s\n' "$rel" "$ln" "$out"
            return 0
        fi
    done
    return 1
}

# Add or update an alias line in a file. Returns 0 when added, 1 when updated.
__bash_aliases_write_alias() {
    local name="$1" quoted="$2" file="$3"
    local tmp="${file}.tmp" found=0 line

    if [[ -f "$file" ]]; then
        : > "$tmp"
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+$name= ]]; then
                printf 'alias %s=%s\n' "$name" "$quoted" >> "$tmp"
                found=1
            else
                printf '%s\n' "$line" >> "$tmp"
            fi
        done < "$file"
        mv "$tmp" "$file"
    fi
    if [[ $found -eq 0 ]]; then
        printf 'alias %s=%s\n' "$name" "$quoted" >> "$file"
        return 0
    fi
    return 1
}

# Find files defining a plain alias name.
__bash_aliases_find_alias() {
    grep -rlnE "^[[:space:]]*alias[[:space:]]+$1=" "$BASH_ALIASES_ROOT" --include=*.sh 2>/dev/null | grep -v '/_core/'
}

# ------------------------------------------------------------------
# list
# ------------------------------------------------------------------
aliases_list() {
    local filter="${1:-}"
    local CYAN=$'\e[36m' GREEN=$'\e[32m' NC=$'\e[0m'
    local file rel line name value entries count total=0
    local fname fline fbody

    if [[ -n "$filter" && ! "$filter" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
        echo "Usage: aliases list [PREFIX]"
        return 1
    fi

    shopt -s globstar
    for file in "$BASH_ALIASES_ROOT"/**/*.sh; do
        [[ -f "$file" ]] || continue
        [[ "$file" == */_core/* ]] && continue
        count=0
        entries=""
        # --- aliases ---
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+([a-zA-Z0-9_.-]+)= ]]; then
                name="${BASH_REMATCH[1]}"
                if [[ -z "$filter" || "$name" == "$filter"* ]]; then
                    value="${line#*=}"
                    if [[ ${#value} -gt 100 ]]; then
                        value="${value:0:100}…"
                    fi
                    entries+="$(printf '  %s%-28s%s%s\n' "$GREEN" "$name" "$NC" "$value")"$'\n'
                    ((count++))
                fi
            fi
        done < "$file"
        # --- functions ---
        while IFS=: read -r fline line; do
            if [[ "$line" =~ ^[[:space:]]*(function[[:space:]]+)?([a-zA-Z0-9_.-]+)[[:space:]]*\(\) ]]; then
                fname="${BASH_REMATCH[2]}"
                if [[ -z "$filter" || "$fname" == "$filter"* ]]; then
                    fbody="$(__bash_aliases_extract_function "$file" "$fname")"
                    [[ -z "$fbody" ]] && continue
                    rel="${file#$BASH_ALIASES_ROOT/}"
                    entries+="$(printf '  %s%-28s%s(function)  [%s:%s]\n' "$GREEN" "$fname" "$NC" "$rel" "$fline")"$'\n'
                    if [[ -n "$filter" ]]; then
                        entries+="$(__bash_aliases_highlight "$fbody")"$'\n'
                    fi
                    ((count++))
                fi
            fi
        done < <(grep -nE "^\s*(function\s+)?[a-zA-Z0-9_.-]+\s*\(\).*\{?" "$file")
        # --- emit ---
        if [[ $count -gt 0 ]]; then
            rel="${file#$BASH_ALIASES_ROOT/}"
            printf '%s== %s (%d)%s\n' "$CYAN" "$rel" "$count" "$NC"
            printf '%s' "$entries"
            ((total+=count))
        fi
    done

    if [[ $total -eq 0 ]]; then
        echo "No aliases found${filter:+ matching '$filter'}."
        return 1
    fi
    printf '%s%d alias(es)/function(s) total%s\n' "$CYAN" "$total" "$NC"
}

# ------------------------------------------------------------------
# which
# ------------------------------------------------------------------
aliases_which() {
    local name="$1"
    local CYAN=$'\e[36m' NC=$'\e[0m'
    local file rel line val found=0 body

    if [[ -z "$name" || ! "$name" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
        echo "Usage: aliases which NAME"
        return 1
    fi

    shopt -s globstar
    for file in "$BASH_ALIASES_ROOT"/**/*.sh; do
        [[ -f "$file" && "$file" != */_core/* ]] || continue
        line=$(grep -nE "^[[:space:]]*alias[[:space:]]+$name=" "$file" | head -n1)
        if [[ -n "$line" ]]; then
            found=1
            rel="${file#$BASH_ALIASES_ROOT/}"
            printf '%s%s:%s%s  alias %s\n' "$CYAN" "$rel" "${line%%:*}" "$NC" "$name"
            val="${line#*=}"
            # If the alias simply wraps a function, show that function too.
            if [[ "$val" =~ ^\"?([a-zA-Z0-9_.-]+)\"?$ ]]; then
                body="$(__bash_aliases_find_function "${BASH_REMATCH[1]}")"
                if [[ -n "$body" ]]; then
                    printf '  -> resolves to function %s:\n' "${BASH_REMATCH[1]}"
                    __bash_aliases_highlight "${body#*$'\n'}"
                fi
            fi
            continue
        fi
        body="$(__bash_aliases_extract_function "$file" "$name")"
        if [[ -n "$body" ]]; then
            found=1
            rel="${file#$BASH_ALIASES_ROOT/}"
            ln=$(grep -nE "^\s*(function\s+)?$name\s*\(\).*\{?" "$file" | head -n1 | cut -d: -f1)
            printf '%s%s:%s%s  function %s\n' "$CYAN" "$rel" "$ln" "$NC" "$name"
            __bash_aliases_highlight "$body"
        fi
    done

    if [[ $found -eq 0 ]]; then
        echo "No alias or function named '$name' found."
        return 1
    fi
}

# ------------------------------------------------------------------
# search
# ------------------------------------------------------------------
aliases_search() {
    local keyword="$1" matches
    local CYAN=$'\e[36m' NC=$'\e[0m'

    if [[ -z "$keyword" ]]; then
        echo "Usage: aliases search KEYWORD"
        return 1
    fi

    matches=$(grep -rni "$keyword" "$BASH_ALIASES_ROOT" --include=*.sh 2>/dev/null \
        | grep -iE "alias[[:space:]]+|\(\)" \
        | grep -v '/_core/')

    if [[ -z "$matches" ]]; then
        echo "No matches for '$keyword'."
        return 1
    fi
    printf '%s\n' "$matches" | sed "s|$BASH_ALIASES_ROOT/||"
}

# ------------------------------------------------------------------
# add
# ------------------------------------------------------------------
aliases_add() {
    local name file content quoted

    if [[ $# -eq 3 ]]; then
        # al a CATEGORY NAME "CMD"        -> CATEGORY.sh (may be nested, e.g. net/some)
        file="$(__bash_aliases_resolve_file "$1")"
        name="$2"
        content="$3"
    elif [[ $# -eq 2 ]]; then
        if [[ "$1" == */* ]]; then
            # al a CATEGORY/NAME "CMD"    -> CATEGORY/NAME.sh (path given, name = basename)
            file="$(__bash_aliases_resolve_file "$1")"
            name="${1##*/}"
        else
            # al a NAME "CMD"             -> _misc.sh (loose, uncategorized alias)
            file="$BASH_ALIASES_ROOT/$BASH_ALIASES_MISC_FILE"
            name="$1"
        fi
        content="$2"
    else
        echo "Usage:"
        echo "  aliases add NAME \"COMMAND\"                # -> ~/bash_aliases/_misc.sh"
        echo "  aliases add CATEGORY NAME \"COMMAND\"       # -> ~/bash_aliases/CATEGORY.sh"
        echo "  aliases add CATEGORY/SUB NAME \"COMMAND\"   # -> ~/bash_aliases/CATEGORY/SUB.sh"
        return 1
    fi

    if [[ ! "$name" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
        echo "Invalid alias name: '$name'"
        return 1
    fi
    if [[ -z "$content" ]]; then
        echo "Empty command for alias '$name'."
        return 1
    fi

    mkdir -p "$(dirname "$file")"
    quoted="$(__bash_aliases_squote "$content")"
    if __bash_aliases_write_alias "$name" "$quoted" "$file"; then
        echo "Added alias '$name' to ${file#$BASH_ALIASES_ROOT/}"
    else
        echo "Updated existing alias '$name' in ${file#$BASH_ALIASES_ROOT/}"
    fi
    echo "Run 'rehash' (or open a new shell) to use it."
}

# ------------------------------------------------------------------
# edit
# ------------------------------------------------------------------
aliases_edit() {
    local input="$1"
    local line_number="$2"
    local file_path

    if [[ -z "$input" ]]; then
        echo "Usage: aliases edit [NAME | CATEGORY/FILE] [LINE]"
        return 1
    fi

    if [[ $input == /* ]]; then
        # Edit a category file at the root by name: /net -> net.sh
        local file="${input#/}"
        local full_path="$BASH_ALIASES_ROOT/$file.sh"

    elif [[ $input == */* ]]; then
        # If input contains a slash, treat it as category/file (possibly nested)
        local dir="${input%/*}"
        local file="${input##*/}"
        file="${file%.sh}"

        local full_path="$BASH_ALIASES_ROOT/$dir/$file.sh"

    else
        # Search for the alias or function in all .sh files (incl. _misc.sh)
        local file_path=$(find "$BASH_ALIASES_ROOT" -name "*.sh" -exec grep -Hn -E "alias $input=|$input\(\)|$input \(\)" {} + | head -n 1)

        if [[ -z "$file_path" ]]; then
            echo "Alias or function '$input' not found. Creating a new file at the root."
            local full_path="$BASH_ALIASES_ROOT/$input.sh"
        else
            local full_path=$(echo "$file_path" | cut -d: -f1)
            local line=$(echo "$file_path" | cut -d: -f2)
            line_number=${line_number:-$line}
        fi
    fi

    # Ensure the directory exists
    mkdir -p "$(dirname "$full_path")"

    # Open the file with the editor
    if [[ -n "$line_number" && "$line_number" =~ ^[0-9]+$ ]]; then
        __bash_aliases_editor_open "$full_path" "$line_number"
    else
        __bash_aliases_editor_open "$full_path"
    fi
}

# ------------------------------------------------------------------
# remove
# ------------------------------------------------------------------
aliases_remove() {
    local name="$1" files line tmp found=0

    if [[ -z "$name" ]]; then
        echo "Usage: aliases remove ALIAS_NAME"
        return 1
    fi

    files=$(__bash_aliases_find_alias "$name")
    if [[ -z "$files" ]]; then
        echo "Alias '$name' not found."
        return 1
    fi

    while IFS= read -r file; do
        tmp="${file}.tmp"
        : > "$tmp"
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+$name= ]]; then
                found=1
            else
                printf '%s\n' "$line" >> "$tmp"
            fi
        done < "$file"
        mv "$tmp" "$file"
        [[ -s "$file" ]] || rm -f "$file"
        echo "Removed alias '$name' from ${file#$BASH_ALIASES_ROOT/}"
    done <<< "$files"

    if [[ $found -eq 0 ]]; then
        echo "Alias '$name' not found."
        return 1
    fi
    echo "Run 'rehash' (or open a new shell) to use it."
}

# ------------------------------------------------------------------
# move
# ------------------------------------------------------------------
aliases_move() {
    local src_file="" name dest_file line l2 tmp

    if [[ $# -eq 3 ]]; then
        src_file="$(__bash_aliases_resolve_file "$1")"
        name="$2"
        dest_file="$(__bash_aliases_resolve_file "$3")"
    elif [[ $# -eq 2 ]]; then
        name="$1"
        dest_file="$(__bash_aliases_resolve_file "$2")"
        src_file="$(__bash_aliases_find_alias "$name" | head -n 1)"
    else
        echo "Usage:"
        echo "  aliases move NAME CATEGORY/FILE             # move NAME into CATEGORY/FILE.sh"
        echo "  aliases move CATEGORY/FILE NAME DEST_FILE   # move NAME from a specific file"
        return 1
    fi

    if [[ -z "$src_file" || ! -f "$src_file" ]]; then
        echo "Alias '$name' not found."
        return 1
    fi

    line=$(grep -E "^[[:space:]]*alias[[:space:]]+$name=" "$src_file" | head -n 1)
    if [[ -z "$line" ]]; then
        echo "Alias '$name' not found in ${src_file#$BASH_ALIASES_ROOT/}."
        return 1
    fi

    mkdir -p "$(dirname "$dest_file")"

    # Remove the alias from the source file
    tmp="${src_file}.tmp"
    : > "$tmp"
    while IFS= read -r l2; do
        [[ "$l2" =~ ^[[:space:]]*alias[[:space:]]+$name= ]] || printf '%s\n' "$l2" >> "$tmp"
    done < "$src_file"
    mv "$tmp" "$src_file"
    [[ -s "$src_file" ]] || rm -f "$src_file"

    # Append the alias to the destination file
    printf '%s\n' "$line" >> "$dest_file"

    echo "Moved alias '$name' to ${dest_file#$BASH_ALIASES_ROOT/}"
    echo "Run 'rehash' (or open a new shell) to use it."
}

# ------------------------------------------------------------------
# install - preset / category selection and framework upgrade
# ------------------------------------------------------------------
aliases_install() {
    local arg="${1:-}"
    shift 2>/dev/null

    case "$arg" in
        ""|h|help|-h|--help)    aliases_install_help ;;
        upgrade)
            command -v git >/dev/null 2>&1 || { echo "Error: git is not installed." >&2; return 1; }
            git -C "$BASH_ALIASES_ROOT" pull --ff-only "$@" || return 1
            echo "Upgrade complete. Rehashing..."
            rehash_aliases
            ;;
        -*)
            __ba_preset_toggle "${arg#-}" off ;;
        full)
            printf 'full\n' > "$BASH_ALIASES_ROOT/.preset"
            echo "Preset set to: full"
            rehash_aliases
            ;;
        *)
            local pnames p found=""
            for p in $(compgen -A variable | grep '^PRESET_' | sed 's/^PRESET_//'); do
                [[ "$p" == "$arg" ]] && found=1
            done
            if [[ -n "$found" ]]; then
                printf '%s\n' "$arg" > "$BASH_ALIASES_ROOT/.preset"
                echo "Preset set to: $arg"
                rehash_aliases
            else
                __ba_preset_toggle "$arg" on
            fi
            ;;
    esac
}

__ba_preset_toggle() {
    local cat="$1" want="$2"

    [[ -e "$BASH_ALIASES_ROOT/$cat.sh" || -d "$BASH_ALIASES_ROOT/$cat" ]] \
        || { echo "Unknown category or preset: $cat (see: al tree)" >&2; return 1; }

    __ba_preset_load
    local allowed=0
    __ba_preset_allows "$cat" && allowed=1

    if { [[ "$want" == on ]] && (( allowed )); } || { [[ "$want" == off ]] && (( ! allowed )); }; then
        echo "'$cat' is already ${want}. Nothing to do."
        return 0
    fi

    local cur=() t out=()
    [[ -s "$BASH_ALIASES_ROOT/.preset" ]] && read -ra cur < "$BASH_ALIASES_ROOT/.preset"
    out+=("${cur[0]:-full}")
    for t in "${cur[@]:1}"; do
        [[ "$t" == "$cat" || "$t" == "-$cat" ]] || out+=("$t")
    done
    [[ "$want" == on ]] && out+=("$cat") || out+=("-$cat")

    printf '%s\n' "${out[*]}" > "$BASH_ALIASES_ROOT/.preset"
    echo "Category '$cat' ${want}."
    echo "Note: run 'rehash'; open a new shell to fully unload disabled aliases."
}

aliases_install_help() {
    __ba_preset_load
    local pvars p name names=""
    pvars=$(compgen -A variable | grep '^PRESET_' | grep -v '^PRESET_ON$\|^PRESET_OFF$')
    for p in $pvars; do
        name="${p#PRESET_}"
        [[ "$name" == ON || "$name" == OFF ]] && continue
        names+="$name "
    done

    cat <<EOF
Usage: al install [ARG]

  (no arg)              status: current preset, enabled/disabled categories
  <preset>              activate a predefined preset: ${names:-}(see _core/presets.sh)
  <category>            additionally enable one category   e.g.: al install python
  -<category>           disable one category             e.g.: al install -wifi
  upgrade               fetch latest framework + files (git pull), then rehash

Categories are the .sh files listed by: al tree
Disabled categories stay on disk - they are simply not sourced.
A per-machine selection lives in '$BASH_ALIASES_ROOT/.preset' (not committed).
After switching presets run 'rehash'; a new shell fully unloads disabled aliases.
EOF

    if [[ -z "${1:-}" ]]; then
        echo
        aliases_install_status
    fi
}

aliases_install_status() {
    __ba_preset_load
    local f rel mark
    local extra=""
    ((${#BASH_ALIASES_PRESET_ON[@]} || ${#BASH_ALIASES_PRESET_OFF[@]})) \
        && extra=" (+${BASH_ALIASES_PRESET_ON[*]:--} ${BASH_ALIASES_PRESET_OFF[*]/#/-})"
    echo "Current preset: $BASH_ALIASES_PRESET_NAME$extra   [$BASH_ALIASES_ROOT/.preset]"
    echo
    for f in "$BASH_ALIASES_ROOT"/*.sh; do
        rel="${f##*/}"
        [[ "$rel" == "_*.sh" ]] && continue
        if __ba_preset_allows "${rel%.sh}"; then mark="[x]"; else mark="[ ]"; fi
        echo "  $mark $rel"
    done
}

# ------------------------------------------------------------------
# tree
# ------------------------------------------------------------------
aliases_tree() {
    local root="$BASH_ALIASES_ROOT" f d g rel mark
    __ba_preset_load

    echo "$root"
    for f in "$root"/*.sh; do
        rel="${f##*/}"
        if [[ "$rel" == _* ]]; then
            echo "    $rel"
            continue
        fi
        if __ba_preset_allows "${rel%.sh}"; then mark="[x]"; else mark="[ ]"; fi
        echo "  $mark $rel"
    done

    for d in "$root"/*/; do
        d="${d%/}"
        rel="${d##*/}"
        [[ "$rel" == "_core" || "$rel" == ".git" ]] && continue
        echo "  --- $rel/"
        find "$d" -name '*.sh' | sort | while read -r g; do
            echo "      ${g#$d/}"
        done
    done
}

# ------------------------------------------------------------------
# config
# ------------------------------------------------------------------
aliases_config() {
    local sub="${1:-open}"
    shift 2>/dev/null

    case "$sub" in
        open|"")    aliases-config ;;
        set)        aliases-config-set "$@" ;;
        get)        aliases-config-get "$@" ;;
        list)       aliases-config-list "$@" ;;
        unset)      aliases-config-unset "$@" ;;
        *)          echo "Unknown config command: $sub" >&2
                    echo "Usage: al config [open|set KEY VAL|get KEY|list|unset KEY]" ;;
    esac
}

# ------------------------------------------------------------------
# help
# ------------------------------------------------------------------
aliases_help() {
    local RED=$'\e[0;31m' GREEN=$'\e[0;32m' YELLOW=$'\e[1;33m' BLUE=$'\e[0;34m'
    local PURPLE=$'\e[0;35m' CYAN=$'\e[1;36m' GRAY=$'\e[0;90m' BOLD=$'\e[1m' NC=$'\e[0m'

    echo -e "${CYAN}${BOLD}Aliases Command Help${NC}"
    echo -e "${CYAN}----------------------${NC}"
    echo -e "Usage: ${GREEN}aliases COMMAND [args...]${NC}   (or: ${GREEN}al CMD [args...]${NC})"
    echo -e "Aliases live in ${GREEN}~/bash_aliases/**/*.sh${NC}; every .sh file is auto-sourced.\n"

    echo -e "${YELLOW}${BOLD}Commands:${NC}"
    echo -e "  ${GREEN}l | list [PREFIX]${NC}        List aliases AND functions (PREFIX shows matching code)"
    echo -e "  ${GREEN}s | search KEYWORD${NC}       Search aliases/functions"
    echo -e "  ${GREEN}a | add ...${NC}              Add an alias (see below)"
    echo -e "  ${GREEN}e | edit TARGET${NC}          Edit a file or alias: NAME (alias/category file) or CATEGORY/FILE (nested)"
    echo -e "  ${GREEN}r | remove NAME${NC}          Remove an alias"
    echo -e "  ${GREEN}m | move ...${NC}             Move an alias between files"
    echo -e "  ${GREEN}t | tree${NC}                Show the directory/file structure"
    echo -e "  ${GREEN}w | which NAME${NC}           Show where NAME is defined + its code"
    echo -e "  ${GREEN}c | config ...${NC}           Config: open | set KEY VAL | get KEY | list | unset KEY"
    echo -e "  ${GREEN}i | install ...${NC}          Presets/categories/upgrade (try: al install help)"
    echo -e "  ${GREEN}sv | save-to-git [MSG]${NC}   Commit & push all alias changes (MSG = commit message)"
    echo -e "  ${GREEN}h | help${NC}                 Show this help message\n"

    echo -e "${YELLOW}${BOLD}Adding Aliases:${NC}"
    echo -e "  ${BLUE}aliases add NAME \"CMD\"${NC}                   ${GRAY}# -> ~/bash_aliases/_misc.sh${NC}"
    echo -e "  ${BLUE}aliases add CATEGORY NAME \"CMD\"${NC}           ${GRAY}# -> ~/bash_aliases/CATEGORY.sh${NC}"
    echo -e "  ${BLUE}aliases add CATEGORY/SUB NAME \"CMD\"${NC}       ${GRAY}# -> ~/bash_aliases/CATEGORY/SUB.sh${NC}"
    echo -e "  ${BLUE}aliases add net wip \"git status\"${NC}         ${GRAY}# -> ~/bash_aliases/net.sh${NC}\n"

    echo -e "${YELLOW}${BOLD}Examples:${NC}"
    echo -e "  ${BLUE}aliases list net${NC}          ${GRAY}# aliases starting with 'net'${NC}"
    echo -e "  ${BLUE}aliases search sqlite${NC}"
    echo -e "  ${BLUE}aliases edit net${NC} ${GRAY}# open the whole net.sh${NC}"
    echo -e "  ${BLUE}aliases remove old-alias${NC}"
    echo -e "  ${BLUE}aliases move wip net${NC} ${GRAY}# move 'wip' into net.sh${NC}\n"

    echo -e "${RED}${BOLD}Note:${NC}${BOLD} Avoid naming aliases after the commands themselves"
    echo -e "      (list, search, add, edit, remove, move, help, ...).${NC}"
}

# ------------------------------------------------------------------
# Tab-completion (completion only - never executes the subcommands)
# ------------------------------------------------------------------

# All alias names defined anywhere under the aliases root.
_aliases_complete_alias() {
    local cur="$1"
    local names
    names=$(grep -rhoE "^[[:space:]]*alias[[:space:]]+[a-zA-Z0-9_.-]+" "$BASH_ALIASES_ROOT" --include=*.sh 2>/dev/null \
        | sed -E 's/.*alias[[:space:]]+//' | sort -u)
    COMPREPLY=( $(compgen -W "$names" -- "$cur") )
}

# Complete a category token: a .sh file at the root, or a nested dir/file.
_aliases_complete_category() {
    local cur="$1" dir opts
    if [[ "$cur" == */* ]]; then
        dir="${cur%/*}"
        [[ -d "$BASH_ALIASES_ROOT/$dir" ]] || { COMPREPLY=(); return; }
        opts=$( { find "$BASH_ALIASES_ROOT/$dir" -maxdepth 1 -name '*.sh' -printf '%f\n' 2>/dev/null | sed 's/\.sh$//';
                 find "$BASH_ALIASES_ROOT/$dir" -maxdepth 1 -type d -printf '%f\n' 2>/dev/null; } \
               | sed "s|^|$dir/;" | grep -v '^$' | tr '\n' ' ' )
    else
        opts=$( { find "$BASH_ALIASES_ROOT" -maxdepth 1 -name '*.sh' ! -name '_config.sh' -printf '%f\n' 2>/dev/null | sed 's/\.sh$//';
                 find "$BASH_ALIASES_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name _core ! -name '.*' -printf '%f\n' 2>/dev/null; } \
               | grep -v '^$' | tr '\n' ' ' )
    fi
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}

# Complete an edit target: alias name and/or category file (root or nested).
# A leading '/' restricts completion to root-level category files.
_aliases_complete_target() {
    local cur="$1" names cats
    names=$(grep -rhoE "^[[:space:]]*alias[[:space:]]+[a-zA-Z0-9_.-]+" "$BASH_ALIASES_ROOT" --include=*.sh 2>/dev/null \
        | sed -E 's/.*alias[[:space:]]+//' | sort -u)
    cats=$(find "$BASH_ALIASES_ROOT" -name _core -prune -o -name '*.sh' -print 2>/dev/null \
        | sed "s|^$BASH_ALIASES_ROOT/||; s|\.sh$||" | grep -v '^$' | tr '\n' ' ')
    if [[ "$cur" == /* ]]; then
        COMPREPLY=( $(compgen -W "$cats" -P / -- "${cur#/}") )
    else
        COMPREPLY=( $(compgen -W "$names $cats" -- "$cur") )
    fi
}

_aliases_complete() {
    local cur
    cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=()

    local cmds="list search add edit remove move tree config which install save-to-git sync help create l s a n + e c r d m t w h i sv g"

    if (( ${COMP_CWORD:-0} == 1 )); then
        COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
        return
    fi

    case "${COMP_WORDS[1]}" in
        a|n|+|add)               _aliases_complete_category "$cur" ;;
        e|c|edit|create)         _aliases_complete_target "$cur" ;;
        r|d|remove|delete|m|move) _aliases_complete_alias "$cur" ;;
        i|install)               _aliases_complete_install "$cur" ;;
    esac
}

_aliases_complete_install() {
    local cur="$1" words="" f
    for f in "$BASH_ALIASES_ROOT"/*.sh; do
        f="${f##*/}"
        [[ "$f" == _*.sh ]] && continue
        words+=" ${f%.sh} -${f%.sh}"
    done
    COMPREPLY=( $(compgen -W "help full minimal standard upgrade $words" -- "$cur") )
}

complete -F _aliases_complete aliases al
