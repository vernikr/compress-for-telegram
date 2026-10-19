#!/bin/bash
#
# Removes the "Compress for Telegram" Quick Action for the current user.
# Only touches the two files the installer creates.

set -euo pipefail

services="$HOME/Library/Services"

rm -rf "${services}/Compress for Telegram.workflow"
rm -f "${services}/encode_hevc.sh"

/System/Library/CoreServices/pbs -flush >/dev/null 2>&1 || true

echo "Removed the Compress for Telegram Quick Action."
