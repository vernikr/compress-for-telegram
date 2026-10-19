#!/bin/bash
#
# Installs the "Compress for Telegram" Quick Action for the current user.
# Copies the Automator workflow and its backend script into ~/Library/Services.

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
services="$HOME/Library/Services"
workflow_src="${repo_dir}/Compress for Telegram.workflow"
workflow_dst="${services}/Compress for Telegram.workflow"
script_src="${repo_dir}/scripts/encode_hevc.sh"
script_dst="${services}/encode_hevc.sh"

mkdir -p "$services"

rm -rf "$workflow_dst"
cp -R "$workflow_src" "$workflow_dst"

cp "$script_src" "$script_dst"
chmod +x "$script_dst"

# Refresh the Services menu so the action shows up without a re-login.
/System/Library/CoreServices/pbs -flush >/dev/null 2>&1 || true

if ! command -v ffmpeg >/dev/null 2>&1 \
    && [ ! -x /opt/homebrew/bin/ffmpeg ] \
    && [ ! -x /usr/local/bin/ffmpeg ] \
    && [ ! -x /opt/local/bin/ffmpeg ]; then
    echo "warning: ffmpeg not found. Install it with: brew install ffmpeg" >&2
fi

echo "Installed:"
echo "  $workflow_dst"
echo "  $script_dst"
echo
echo "Right-click a video in Finder -> Quick Actions -> Compress for Telegram."
echo "If the item does not appear, open System Settings -> Keyboard -> Keyboard"
echo "Shortcuts -> Services and enable it under Files and Folders."
