#!/bin/bash
set -e

# =============================================================================
# Workspace Home Directory Initialization
# =============================================================================
# When Coder mounts a Docker volume to the home directory, the empty volume
# shadows all default files pre-populated by the base image: shell configs,
# Oh My Zsh, .profile, etc.
#
# This script restores those defaults on the first container start by copying
# from /etc/workspace-skel, which is a snapshot of the image home directory
# captured at build time (see Dockerfile).
#
# Marker file : ~/.workspace_initialized
# Source      : /etc/workspace-skel  (built into the image)
# Strategy    : no-clobber copy — existing files are never overwritten,
#               so user customisations added after init are always preserved.
# =============================================================================

MARKER="${HOME}/.workspace_initialized"
WORKSPACE_SKEL="/etc/workspace-skel"

if [ ! -f "${MARKER}" ]; then
    echo "[workspace] First start detected — initializing home directory..."

    if [ -d "${WORKSPACE_SKEL}" ]; then
        # Restore image home defaults (e.g. Oh My Zsh, .zshrc, .bashrc).
        # -T : copy contents of WORKSPACE_SKEL directly into HOME
        # -n : never overwrite files that already exist in HOME
        cp -rTn "${WORKSPACE_SKEL}" "${HOME}"
        echo "[workspace] Restored home defaults from ${WORKSPACE_SKEL}."
    fi

    # Overlay /etc/skel last so any system-level skeleton files that are
    # absent from workspace-skel are still applied.
    if [ -d "/etc/skel" ]; then
        cp -rTn "/etc/skel" "${HOME}"
        echo "[workspace] Applied system skeleton from /etc/skel."
    fi

    touch "${MARKER}"
    echo "[workspace] Home directory initialization complete."
fi

exec "$@"
