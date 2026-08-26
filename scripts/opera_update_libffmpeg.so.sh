#!/bin/bash

alias opera-ffmpeg-update='update_libffmpeg'


update_libffmpeg() {
    local TEMP_DIR=$(mktemp -d)
    local DEST_DIRS=(
        "/usr/lib/x86_64-linux-gnu/opera/"
        "/usr/lib64/opera-stable/"
    )
    local DEST_DIR=""

    # Determine the correct destination directory based on existing paths
    for dir in "${DEST_DIRS[@]}"; do
        if [[ -f "$dir/libffmpeg.so" || -f "$dir/libffmpeg.so.bak" ]]; then
            DEST_DIR="$dir"
            break
        fi
    done

    # Check if a valid destination directory was found
    if [[ -z "$DEST_DIR" ]]; then
        echo "Opera installation not found. Please check your installation."
        rm_tmp_dir "$TEMP_DIR"
        return 1
    fi

    # Download the latest libffmpeg.so
    echo "Downloading libffmpeg.so..."
    local REPO_NAME="nwjs-ffmpeg-prebuilt"
    local OWNER_NAME="nwjs-ffmpeg-prebuilt"
    local RELEASES_API="https://api.github.com/repos/${OWNER_NAME}/${REPO_NAME}/releases/latest"

    # Fetch the latest release information
    local RELEASE_INFO=$(curl -s -H "Accept: application/vnd.github.v3+json" "${RELEASES_API}")

    if [ $? -ne 0 ]; then
        echo "Failed to fetch release information. Is the repository public?"
        rm_tmp_dir "$TEMP_DIR"
        return 1
    fi

    local ZIP_FILE=$(echo "${RELEASE_INFO}" | jq -r ".assets[] | select(.name | contains(\"linux-x64.zip\")) | .browser_download_url")

    if [ -z "$ZIP_FILE" ]; then
        echo "No suitable zip file found in the latest release."
        rm_tmp_dir "$TEMP_DIR"
        return 1
    fi

    echo "Downloading ${ZIP_FILE}..."
    curl -L -o "$TEMP_DIR/${ZIP_FILE##*/}" "${ZIP_FILE}"

    if [ $? -ne 0 ]; then
        echo "Error downloading ${ZIP_FILE}. Please check your internet connection."
        rm_tmp_dir "$TEMP_DIR"
        return 1
    fi

    # Verify the downloaded file exists and is non-empty
    if [[ ! -s "$TEMP_DIR/${ZIP_FILE##*/}" ]]; then
        echo "Downloaded file is missing or empty."
        rm_tmp_dir "$TEMP_DIR"
        return 1
    fi

    # Extract the zip file
    unzip -q -o "$TEMP_DIR/${ZIP_FILE##*/}" -d "$TEMP_DIR/unpacked"

    if [[ ! -f "$TEMP_DIR/unpacked/libffmpeg.so" ]]; then
        echo "libffmpeg.so not found in the downloaded archive."
        rm_tmp_dir "$TEMP_DIR"
        return 1
    fi

    # Backup the existing libffmpeg.so if it exists (AFTER successful download)
    if [[ -f "$DEST_DIR/libffmpeg.so" ]]; then
        echo "Backing up existing libffmpeg.so to libffmpeg.so.bak..."
        sudo mv "$DEST_DIR/libffmpeg.so" "$DEST_DIR/libffmpeg.so.bak"
    fi

    # Replace the existing libffmpeg.so with the new one
    echo "Replacing libffmpeg.so..."
    sudo mv "$TEMP_DIR/unpacked/libffmpeg.so" "$DEST_DIR/"

    # Clean up temporary directory
    rm_tmp_dir "$TEMP_DIR"

    echo "libffmpeg.so updated successfully!"
}


# Function to safely remove a temporary directory
rm_tmp_dir() {
    local dir="$1"

    # Check if the directory starts with /tmp and has no spaces
    if [[ "$dir" == /tmp/* && "$dir" != *\ * ]]; then
        rm -rf "$dir"
        echo "Removed temporary directory: $dir"
    else
        echo "Error: '$dir' is not a valid temporary directory."
    fi
}
