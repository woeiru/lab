#!/usr/bin/env bash
set -euo pipefail

CARD="alsa_card.usb-Native_Instruments_Komplete_Audio_1_0000C5D0-00"
PROFILE="output:analog-stereo+input:analog-stereo"
SOURCE="alsa_input.usb-Native_Instruments_Komplete_Audio_1_0000C5D0-00.analog-stereo"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

need_cmd pactl

if ! pactl info >/dev/null 2>&1; then
  echo "Cannot reach Pulse/PipeWire server. Log into desktop session and retry." >&2
  exit 1
fi

if ! pactl list short cards | awk '{print $2}' | grep -Fxq "$CARD"; then
  echo "Audio card not found: $CARD" >&2
  echo "Available cards:" >&2
  pactl list short cards >&2
  exit 1
fi

echo "Switching card profile to duplex..."
pactl set-card-profile "$CARD" "$PROFILE"
sleep 1

if ! pactl list short sources | awk '{print $2}' | grep -Fxq "$SOURCE"; then
  echo "Mic source did not appear after profile switch: $SOURCE" >&2
  echo "Available sources:" >&2
  pactl list short sources >&2
  exit 1
fi

echo "Setting default source, unmuting, and applying 100% gain..."
pactl set-default-source "$SOURCE"
pactl set-source-mute "$SOURCE" 0
pactl set-source-volume "$SOURCE" 100%

echo
echo "Done. Current defaults:"
pactl info | grep -E "Default Sink|Default Source" || true
echo
echo "Current sources:"
pactl list short sources
echo
echo "Optional test:"
echo "timeout 4 parec --device=@DEFAULT_SOURCE@ --file-format=wav /tmp/mic-test.wav && file /tmp/mic-test.wav"
