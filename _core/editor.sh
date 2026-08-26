
# Resolve which editor to use when none is explicitly configured.
# Order: $BASH_ALIASES_EDITOR -> $EDITOR -> first available common editor.
__bash_aliases_resolve_editor() {
    local e="${BASH_ALIASES_EDITOR:-$EDITOR}"
    if [[ -z "$e" ]]; then
        for c in nano vim vi code codium micro emacs; do
            if command -v "$c" >/dev/null 2>&1; then
                e="$c"
                break
            fi
        done
    fi
    printf '%s' "$e"
}

__bash_aliases_editor_open() {
    local file_name="$1"
    local line_number="${2:-0}"  # Default to 0 if not provided
    local editor="${3:-$(__bash_aliases_resolve_editor)}"  # Editor is the third parameter

    # Check if the second parameter is a number
    if [[ ! "$line_number" =~ ^[0-9]+$ ]]; then
        editor="$line_number"  # Treat it as an editor
        line_number=0          # Reset line number to default
    fi

    case "$editor" in
        codium|code)
            "$editor" -n -g "$file_name:$line_number"
            ;;
        nano|vim|emacs|neovim|gedit|geany)
            "$editor" +"$line_number" "$file_name"
            ;;
        subl|sublime)
            subl "$file_name:$line_number"
            ;;
        webstorm|idea|intellij|atom|pycharm)
            "$editor" "$file_name" --line "$line_number"
            ;;
        textmate)
            mate -l "$line_number" "$file_name"
            ;;
        brackets)
            brackets "$file_name#line=$line_number"
            ;;
        kdevelop)
            kdevelop "$file_name" --line "$line_number"
            ;;
        qtcreator)
            qtcreator "$file_name" -g "$line_number"
            ;;
        jupyter)
            jupyter notebook "$file_name" --LineNumber="$line_number"
            ;;
        bluefish)
            bluefish --line="$line_number" "$file_name"
            ;;
        *)
            echo "Unsupported editor: $editor. I don't know how to open it at certain line numbers."
            echo "Please edit the function 'open_editor' to add support for your editor."
            echo "To edit, use: alias_edit open_editor"
            
            # Attempt to open with the unsupported editor without line number
            "$editor" "$file_name"
            ;;
    esac
}
