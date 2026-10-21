#!/usr/bin/env bash
# Build the watch app with the Connect IQ SDK.
#
#   bash watch/build.sh            # bin/WristAgent.prg for sideload (USB)
#   DEVICE=fr265 bash watch/build.sh
#
# Needs: the SDK (connect-iq-sdk-manager sdk set ^8), the device files
# (connect-iq-sdk-manager device download -d <DEVICE>), and a developer key
# at KEY. With no local Java, the build runs in a Java container.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DEVICE="${DEVICE:-fr165}"
KEY="${KEY:-$HOME/.garmin/developer_key.der}"
SDK="$(connect-iq-sdk-manager sdk current-path 2>/dev/null | tail -1)"
SDK="${SDK%/}"
[ -f "$KEY" ] || { echo "no developer key at $KEY (see README, Step 3)" >&2; exit 1; }
[ -d "$SDK" ] || { echo "no Connect IQ SDK: run connect-iq-sdk-manager sdk set ^8" >&2; exit 1; }
mkdir -p "$HERE/bin"
ARGS=(-jar "$SDK/bin/monkeybrains.jar" -d "$DEVICE" -o bin/WristAgent.prg -f monkey.jungle -y "$KEY" -w)
if command -v java >/dev/null; then
  (cd "$HERE" && java "${ARGS[@]}")
else
  docker run --rm -v "$SDK:$SDK" -v "$HOME/.Garmin:$HOME/.Garmin:ro" -v "$KEY:$KEY:ro" \
    -v "$HERE:/app" -e HOME="$HOME" -w /app maven:3.9-eclipse-temurin-21 java "${ARGS[@]}"
fi
ls -la "$HERE/bin/WristAgent.prg"
