#!/bin/bash

# 64 000 000 bits / video length = target bitrate

MAX_VIDEO_SIZE="60000000"
MAX_AUDIO_SIZE="4000000"

# Check argument

if [[ "$1" == "" ]]; then
	echo "Error: No video file selected"
	echo "Usage: $0 <video-file>"
	exit
fi

# Check if file is video, get duration if it is

DURATION=$(ffprobe -hide_banner "$1" -show_entries format=duration -v quiet -of csv="p=0")

if [[ "$DURATION" == "" ]]; then
	echo Error, ffprobe returned no duration. "$1" is possibly not a video file
	exit
fi

echo "$1" is a video file and is $DURATION seconds long

# Calculate bitrate

ADJUSTED_DURATION=$(printf "%.0f\n" "$DURATION")
VIDEO_BITRATE=$(echo $((MAX_VIDEO_SIZE / ADJUSTED_DURATION*75/100)))
AUDIO_BITRATE=$(echo $((MAX_AUDIO_SIZE / ADJUSTED_DURATION*90/100)))

ffmpeg -i "$1" -c:v libvpx-vp9 -b:v "$VIDEO_BITRATE" -vf scale=1280:720 -c:a libopus -b:a "$AUDIO_BITRATE" "$1-compressed.webm"
