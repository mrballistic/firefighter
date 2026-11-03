#!/usr/bin/env bash
# Install the built game on a USB-connected Playdate and launch it.
#   scripts/install_device.sh            # uses build/CrankAndCatch.pdx (run scripts/build.sh first)
#
# Machines whose endpoint security blocks USB storage cannot use this (the
# disk shows as "not readable"); sideload via play.date instead (see README).
#
# The Playdate must be connected with a data-capable USB cable, awake and
# unlocked (not on the lock screen). Flow: put it in data-disk mode, copy the
# .pdx into /Games, eject, wait for it to come back, then run the game.
# Only this game's folder on the device is replaced; saves (Data/) are untouched.
set -euo pipefail
cd "$(dirname "$0")/.."

SDK="${PLAYDATE_SDK_PATH:-$HOME/Developer/PlaydateSDK}"
PDUTIL="$SDK/bin/pdutil"
PDX="build/CrankAndCatch.pdx"
NAME="$(basename "$PDX")"
VOLUME="/Volumes/PLAYDATE"

[[ -d "$PDX" ]] || { echo "No $PDX; run scripts/build.sh first." >&2; exit 1; }

find_port() { ls /dev/cu.usbmodemPD* 2>/dev/null | head -1 || true; }

wait_for() { # wait_for <description> <test command...>
    local what="$1"; shift
    for _ in $(seq 1 60); do
        if "$@"; then return 0; fi
        sleep 1
    done
    echo "Timed out waiting for $what." >&2
    exit 1
}

if [[ -d "$VOLUME/Games" ]]; then
    echo "Playdate is already mounted in data disk mode."
else
    PORT="$(find_port)"
    [[ -n "$PORT" ]] || { echo "No Playdate found. Connect it with a data cable, wake and unlock it." >&2; exit 1; }
    echo "Playdate on $PORT; switching to data disk mode..."
    "$PDUTIL" "$PORT" datadisk
    echo "(If macOS asks to allow the accessory to connect, click Allow.)"
    wait_for "the PLAYDATE volume" test -d "$VOLUME/Games"
fi

echo "Copying $NAME..."
rsync -a --delete "$PDX/" "$VOLUME/Games/$NAME/"
sync
diskutil eject "$VOLUME" >/dev/null
echo "Ejected; waiting for the Playdate to reconnect..."
wait_for "the Playdate to reconnect" test -n "$(find_port)"
sleep 1

echo "Launching..."
"$PDUTIL" "$(find_port)" run "/Games/$NAME"
echo "Done."
