#!/bin/zsh
# Wrapper to launch a ChucK song with the correct audio device settings.
# Uses --dac:6 (Mac mini Speakers) and --in:0 (no audio input channels) to avoid
# the C920 webcam sample-rate error.
exec chuck --dac:6 --in:0 "$@"
