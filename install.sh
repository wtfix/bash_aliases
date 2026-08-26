#!/bin/bash

# Bash Aliases installer.
# Usage:  curl -fsSL https://raw.githubusercontent.com/wtfix/bash_aliases/main/install.sh | bash
# or:     bash install.sh [preset] [target-dir]
# Presets: minimal (default) | standard | full   (see _core/presets.sh)

set -e

REPO="https://github.com/wtfix/bash_aliases.git"
PRESET="${1:-minimal}"
DIR="${2:-$HOME/bash_aliases}"
RC="$HOME/.bashrc"
[[ -n "${ZSH_VERSION:-}" ]] && RC="$HOME/.zshrc"

command -v git >/dev/null 2>&1 || { echo "Error: git is required (e.g.: apt install git / pkg install git)." >&2; exit 1; }

if [[ -d "$DIR/.git" ]]; then
    echo "Updating existing installation at $DIR ..."
    git -C "$DIR" pull --ff-only
else
    echo "Cloning into $DIR ..."
    git clone --depth 1 "$REPO" "$DIR"
fi

printf '%s\n' "$PRESET" > "$DIR/.preset"
echo "Preset set to: $PRESET (change later with: al install help)"

if grep -q "BASH_ALIASES_ROOT" "$RC" 2>/dev/null; then
    echo "Shell rc already configured: $RC"
else
    {
        echo ''
        echo '# Bash Aliases'
        echo "export BASH_ALIASES_ROOT=\"$DIR\""
        echo '[ -e "$BASH_ALIASES_ROOT/_core/init.sh" ] && source "$BASH_ALIASES_ROOT/_core/init.sh"'
    } >> "$RC"
    echo "Added init snippet to: $RC"
fi

echo
echo "Done. Start a new shell or run: source $RC"
