#!/bin/bash

alias backup-projects="rclone sync $HOME/Projects $BASH_ALIASES_RCLONE_REMOTE:Projects --exclude-from $HOME/Projects/backup_exclude.txt"

alias backup-aliases="rclone sync $BASH_ALIASES_ROOT $BASH_ALIASES_RCLONE_REMOTE:bash_aliases"

alias backup-docs="rclone sync $HOME/Documents $BASH_ALIASES_RCLONE_REMOTE:Documents"

backup-all() {
    echo "Backup Projects"
    backup-projects

    echo "Backup Aliases"
    backup-aliases

    echo "Backup Docs"
    backup-docs
}


function backup-restore {
    if [ -z "$1" ]; then
        echo "Usage: backup-restore <file-path>"
        return 1
    fi

    local file_path="$1"
    local remote_path=""
    local base_name=$(basename "$file_path")

    if [[ "$file_path" == *"/Projects/"* ]]; then
        remote_path="$BASH_ALIASES_RCLONE_REMOTE:Projects/"
    elif [[ "$file_path" == *"$BASH_ALIASES_ROOT"* ]]; then
        remote_path="$BASH_ALIASES_RCLONE_REMOTE:bash_aliases/"
    else
        echo "Error: File path does not match known backup locations."
        return 1
    fi

    local remote_file_path="$remote_path$base_name"

    rclone copy "$remote_file_path" "$(dirname "$file_path")" --progress

    if [ $? -eq 0 ]; then
        echo "File $file_path restored successfully."
    else
        echo "Error restoring file $file_path"
    fi
}


function backup-single-file() {
    # Does not working as expected
    # TODO: fix paths
    local file_path="$1"
    local relative_path="${file_path#$HOME}"

    echo "Backing up $file_path to Google Drive..."

    # Remove trailing slash if present
    relative_path=$(echo "$relative_path" | sed 's/\/$//')

    if rclone sync "$file_path" "$BASH_ALIASES_RCLONE_REMOTE:_FILES/$relative_path"; then
        echo "Backup successful: $file_path -> $BASH_ALIASES_RCLONE_REMOTE:_FILES/$relative_path"
    else
        echo "Backup failed: Unable to sync $file_path"
        return 1
    fi
}

function backup-restore-single-file() {
    # Does not working as expected
    # TODO: fix paths
    local file_path="$1"
    local relative_path="${file_path#$HOME}"

    echo "Restoring $file_path from Google Drive..."

    # Remove trailing slash if present
    relative_path=$(echo "$relative_path" | sed 's/\/$//')

    if rclone copy "$BASH_ALIASES_RCLONE_REMOTE:_FILES/$relative_path" "$file_path"; then
        echo "Restore successful: $BASH_ALIASES_RCLONE_REMOTE:_FILES/$relative_path -> $file_path"
    else
        echo "Restore failed: Unable to copy from Google Drive"
        return 1
    fi
}