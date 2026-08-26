#!/bin/bash


# Set the default editor;
# Supported Editors: codium, code, nano, vim, emacs, neovim, zed,
#   subl, atom, webstorm, textmate, idea, brackets, gedit,
#    kdevelop, qtcreator, jupyter, geany, bluefish
# Add support for more editors by `aliases edit _core/editor`
export BASH_ALIASES_EDITOR="nano"


export BASH_ALIASES_LOG_LEVEL="INFO"


# Catch-all location for loose, uncategorized aliases (e.g. `al a pp2 "..."`).
export BASH_ALIASES_MISC_FILE="_misc.sh"


# Syntax-highlighting command for code shown by `al l`/`al w` and by `q`/`qq`.
# It receives text on stdin and writes rendered text to stdout.
# If the command's binary is not installed, output falls back to plain text.
# Set to empty ("") to always use plain text. Examples:
#   glow -s dracula -        (default; needs `glow`)
#   glow -s github -         (light style)
#   bat -l bash --style=plain --paging=never -
export BASH_ALIASES_HIGHLIGHT_CMD="glow -s dracula - -w 0"


# rclone remote name used by backup.sh (e.g. "google-drive-email").
# Set this to your own rclone remote. Left empty here as a placeholder so
# personal data is kept out of the public repository; override it in your
# shell rc (before sourcing init.sh) or export it in your environment.
if [ -z "${BASH_ALIASES_RCLONE_REMOTE:-}" ]; then
    export BASH_ALIASES_RCLONE_REMOTE=""
fi
