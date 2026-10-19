#!/bin/bash
#
# Compress for Telegram — encoding backend for the macOS Quick Action.
#
# Shrinks videos to H.265/HEVC in a .mov container (tagged hvc1 so QuickTime and
# Telegram can play them) and re-encodes audio-only files to AAC.
#
# Usage: encode_hevc.sh <file> [file ...]
#
# Env overrides:
#   CRF           x265 quality, lower = better/bigger (default: 28)
#   PRESET        x265 speed preset (default: slow)
#   AUDIO_BITRATE AAC bitrate for audio-only inputs (default: 32k)

set -euo pipefail

CRF="${CRF:-28}"
PRESET="${PRESET:-slow}"
AUDIO_BITRATE="${AUDIO_BITRATE:-32k}"

# ffmpeg ships in different prefixes depending on the installer
# (Homebrew on Apple Silicon, Homebrew on Intel, MacPorts), and this action is
# started from Finder, which does not inherit an interactive shell's PATH.
resolve_tool() {
    local name="$1" dir
    if command -v "$name" >/dev/null 2>&1; then
        command -v "$name"
        return 0
    fi
    for dir in /opt/homebrew/bin /usr/local/bin /opt/local/bin; do
        if [ -x "${dir}/${name}" ]; then
            printf '%s\n' "${dir}/${name}"
            return 0
        fi
    done
    return 1
}

FFMPEG="$(resolve_tool ffmpeg)" || {
    echo "error: ffmpeg not found. Install it with 'brew install ffmpeg' (or 'sudo port install ffmpeg')." >&2
    exit 1
}
FFPROBE="$(resolve_tool ffprobe)" || {
    echo "error: ffprobe not found. It ships with ffmpeg." >&2
    exit 1
}

human_size() {
    du -h "$1" | awk '{print $1}'
}

work="$(mktemp -d "${TMPDIR:-/tmp}/compress-for-telegram.XXXXXX")"
trap 'rm -rf "$work"' EXIT

for f in "$@"; do
    if [ ! -f "$f" ]; then
        echo "Skipping (not a regular file): $f" >&2
        continue
    fi

    dir="$(dirname "$f")"
    base="$(basename "$f")"
    name="${base%.*}"
    out="${dir}/${name}_hevc.mov"
    tmp_out="${work}/encoded.mov"

    echo "Processing: $f"

    # Does the input carry a video stream?
    has_video="$("$FFPROBE" -v error -select_streams v -show_entries stream=index -of csv=p=0 "$f" || true)"

    if [ -n "$has_video" ]; then
        # Video: re-encode to HEVC, copy the audio track as-is.
        "$FFMPEG" -y -loglevel error -stats -i "$f" \
            -c:v libx265 -preset "$PRESET" -crf "$CRF" -tag:v hvc1 \
            -c:a copy -map 0:v -map "0:a?" -shortest "$tmp_out"

        # Telegram's players dislike silent video; give it a silent AAC track.
        if ! "$FFPROBE" -v error -select_streams a:0 \
            -show_entries stream=codec_type -of csv=p=0 "$tmp_out" | grep -q audio; then
            echo "No audio detected, adding a silent track..."
            "$FFMPEG" -y -loglevel error -stats -i "$tmp_out" \
                -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
                -c:v copy -map 0:v -map 1:a -c:a aac -b:a 128k -shortest "${work}/with-audio.mov"
            mv "${work}/with-audio.mov" "$tmp_out"
        fi
    else
        # Audio only: remux first (fixes fragmented AAC), then re-encode.
        echo "No video stream, re-encoding audio..."
        "$FFMPEG" -y -loglevel error -stats -i "$f" -c copy "${work}/source.m4a"
        "$FFMPEG" -y -loglevel error -stats -i "${work}/source.m4a" \
            -c:a aac -b:a "$AUDIO_BITRATE" "$tmp_out"
    fi

    mv "$tmp_out" "$out"
    echo "Finished: $out ($(human_size "$f") -> $(human_size "$out"))"
done
