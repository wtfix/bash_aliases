

# Open the config file in the default editor.
# Honours BASH_ALIASES_EDITOR, falling back to $EDITOR or a common editor.
aliases-config() {
    if [[ -z "$BASH_ALIASES_EDITOR" ]]; then
        local ed
        ed="$(__bash_aliases_resolve_editor)"
        if [[ -z "$ed" ]]; then
            echo "No editor configured. Set one with: al config set editor <nano|vim|code|...>"
            return 1
        fi
        echo "BASH_ALIASES_EDITOR is not set; opening with '$ed'." >&2
        echo "Set a default with: al config set editor <name>" >&2
    fi
    __bash_aliases_editor_open "$BASH_ALIASES_CONFIG_FILE"
}


# Get a config value. Usage: al config get KEY
aliases-config-get() {
    local key="$1"
    if [[ -z "$key" ]]; then
        echo "Usage: al config get KEY"
        return 1
    fi
    local val
    val=$(grep -E "^\s*export\s+$key=" "$BASH_ALIASES_CONFIG_FILE" 2>/dev/null \
        | head -n1 | sed -E "s/^\s*export\s+$key=//" | tr -d '"' | tr -d "'")
    if [[ -z "$val" ]]; then
        echo "'$key' is not set."
        return 1
    fi
    printf '%s\n' "$val"
}

# Set a config value and save it to _config.sh. Usage: al config set KEY VALUE
aliases-config-set() {
    local key="$1" value="$2"
    if [[ -z "$key" || -z "$value" ]]; then
        echo "Usage: al config set KEY VALUE"
        return 1
    fi
    if grep -qE "^\s*export\s+$key=" "$BASH_ALIASES_CONFIG_FILE" 2>/dev/null; then
        sed -i -E "s|^(\s*export $key=).*|\1\"$value\"|" "$BASH_ALIASES_CONFIG_FILE"
    else
        printf 'export %s="%s"\n' "$key" "$value" >> "$BASH_ALIASES_CONFIG_FILE"
    fi
    echo "Set $key=$value"
}

# Unset a config value. Usage: al config unset KEY
aliases-config-unset() {
    local key="$1"
    if [[ -z "$key" ]]; then
        echo "Usage: al config unset KEY"
        return 1
    fi
    sed -i -E "/^\s*export\s+$key=/d" "$BASH_ALIASES_CONFIG_FILE"
    echo "Unset $key"
}

# List all configured values. Usage: al config list
aliases-config-list() {
    grep -E "^\s*export\s+" "$BASH_ALIASES_CONFIG_FILE" 2>/dev/null \
        | sed -E 's/^\s*export\s+//; s/=/ = /'
}
