#!/usr/bin/env bash

set -o nounset            # Fail on use of unset variable.
set -o errexit            # Exit on command failure.
set -o pipefail           # Exit on failure of any command in a pipeline.
set -o errtrace           # Trap errors in functions and subshells.
shopt -s inherit_errexit  # Inherit the errexit option status in subshells.

# Print a useful trace when an error occurs
trap 'echo Error when executing ${BASH_COMMAND} at line ${LINENO}! >&2' ERR

# Get inputs from command line arguments
if [[ $# != 4 ]]; then
    echo "Error: 'mount-file.bash' requires *four* args." >&2
    exit 1
fi

mountPoint="$1"
targetFile="$2"
method="$3"
debug="$4"

trace() {
    if (( debug )); then
      echo "$@"
    fi
}
if (( debug )); then
    set -o xtrace
fi

# Ensure parent directories exist for both mountPoint and targetFile
mkdir -p "$(dirname "$mountPoint")"
mkdir -p "$(dirname "$targetFile")"

if findmnt --mountpoint "$mountPoint" >/dev/null 2>&1; then
    trace "mount already exists at $mountPoint, ignoring"
    exit 0
fi
if [[ -L $mountPoint && $(readlink -f "$mountPoint") == "$targetFile" ]]; then
    trace "$mountPoint already links to $targetFile, ignoring"
    exit 0
fi
# Remove any existing file/symlink at mountPoint (but not active mounts)
if [[ -e $mountPoint || -L $mountPoint ]]; then
    trace "$mountPoint exists, removing it to set up persistence"
    rm -f "$mountPoint" 2>/dev/null || true
fi
if [[ $method == "auto" && -e $targetFile ]]; then
    touch "$mountPoint"
    mount -o bind "$targetFile" "$mountPoint"
elif [[ $method == "auto" && $mountPoint == "/etc/machine-id" ]]; then
    # Work around an issue with persisting /etc/machine-id. For more
    # details, see https://github.com/nix-community/impermanence/pull/242
    echo "Creating initial /etc/machine-id"
    echo "uninitialized" > "$targetFile"
    touch "$mountPoint"
    mount -o bind "$targetFile" "$mountPoint"
else
    ln -sf "$targetFile" "$mountPoint"
fi
