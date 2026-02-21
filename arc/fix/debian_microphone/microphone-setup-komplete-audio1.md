# Microphone Setup Runbook (Debian 13 + PipeWire)

This is the quick recovery procedure for microphone input on this machine.

## What Broke Last Time

The USB interface `Komplete Audio 1` was on output-only profile:

- `output:iec958-stereo`

That profile exposes no usable mic source in PipeWire/Pulse.

## One-Time Checks

```bash
uname -a
cat /etc/os-release
pactl info
pactl list short cards
```

## Fix: Switch Card to Duplex Profile

```bash
pactl set-card-profile alsa_card.usb-Native_Instruments_Komplete_Audio_1_0000C5D0-00 output:analog-stereo+input:analog-stereo
```

## Set Default Mic Source + Unmute + Gain

```bash
pactl set-default-source alsa_input.usb-Native_Instruments_Komplete_Audio_1_0000C5D0-00.analog-stereo
pactl set-source-mute alsa_input.usb-Native_Instruments_Komplete_Audio_1_0000C5D0-00.analog-stereo 0
pactl set-source-volume alsa_input.usb-Native_Instruments_Komplete_Audio_1_0000C5D0-00.analog-stereo 100%
```

## Verify

```bash
pactl info | grep "Default Source"
pactl list short sources
```

Expected source:

- `alsa_input.usb-Native_Instruments_Komplete_Audio_1_0000C5D0-00.analog-stereo`

## Quick Recording Test

Use `parec` (works through PipeWire/Pulse):

```bash
timeout 4 parec --device=@DEFAULT_SOURCE@ --file-format=wav /tmp/mic-test.wav
ls -lh /tmp/mic-test.wav
file /tmp/mic-test.wav
```

## Optional: GUI Check (KDE)

Open audio settings and confirm:

- Input device is `Komplete Audio 1 Analog Stereo`
- Input level meter moves when speaking
- Correct app has mic permissions

## If Mic Still Missing

1. Restart user audio services:
```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```
2. Re-check profiles and sources:
```bash
pactl list short cards
pactl list short sources
```
3. Confirm USB interface is present:
```bash
cat /proc/asound/cards
ls -la /dev/snd
```

## Notes

- `arecord` may fail on this host for PipeWire paths; prefer `parec` or `pw-record`.
- If you intentionally want motherboard mic instead, switch that card profile from `off` to a duplex/input profile.
