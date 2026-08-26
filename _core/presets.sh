#!/bin/bash

# Named bundles of root-level category files sourced at startup.
# PRESET_full stays empty on purpose: "full" means "everything on disk".

PRESET_minimal=(bash net files)
PRESET_standard=(bash net files find systemctl clipboard _misc)
PRESET_full=()

__ba_preset_load() {
    BASH_ALIASES_PRESET_NAME="full"
    BASH_ALIASES_PRESET_ON=()
    BASH_ALIASES_PRESET_OFF=()

    local pf="$BASH_ALIASES_ROOT/.preset"
    [[ -s "$pf" ]] || return 0

    local tok t var
    read -ra tok < "$pf"
    BASH_ALIASES_PRESET_NAME="${tok[0]:-full}"
    for t in "${tok[@]:1}"; do
        case "$t" in
            -*) BASH_ALIASES_PRESET_OFF+=("${t#-}") ;;
            *)  BASH_ALIASES_PRESET_ON+=("$t") ;;
        esac
    done

    if [[ "$BASH_ALIASES_PRESET_NAME" != "full" ]]; then
        var="PRESET_${BASH_ALIASES_PRESET_NAME}"
        if [[ -z "${!var+x}" ]]; then
            echo "Warning: unknown preset '$BASH_ALIASES_PRESET_NAME' in .preset - falling back to 'full'." >&2
            BASH_ALIASES_PRESET_NAME="full"
        fi
    fi
}

__ba_preset_allows() {
    local cat="$1" t var
    for t in "${BASH_ALIASES_PRESET_OFF[@]}"; do
        [[ "$t" == "$cat" ]] && return 1
    done
    [[ "$BASH_ALIASES_PRESET_NAME" == "full" ]] && return 0
    local -n arr="PRESET_${BASH_ALIASES_PRESET_NAME}"
    local t
    for t in "${arr[@]}" "${BASH_ALIASES_PRESET_ON[@]}"; do
        [[ "$t" == "$cat" ]] && return 0
    done
    return 1
}
