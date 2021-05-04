#!/bin/bash

# 64 000 000 bits / video length = target bitrate

MAX_SIZE="64000000"

# Check argument

if [[ "$1" == "" ]]; then
	echo "Error: No video file selected"
	echo "Usage: $0 <video-file>"
	exit
fi

# Check if file is video, get duration if it is

DURATION=$(ffprobe -hide_banner "$1" -show_entries format=duration -v quiet -of csv="p=0" || echo Error: "$1" is not a video file; exit)

if [[ "$DURATION" == "" ]]; then
	exit
fi

echo "$1" is a video file and is $DURATION seconds long

# Calculate bitrate

ADJUSTED_DURATION=$(printf "%.0f\n" "$DURATION")
BITRATE=$(echo $((MAX_SIZE / ADJUSTED_DURATION*75/100)))

echo video should have a bitrate of $(((MAX_SIZE / ADJUSTED_DURATION)/1000)) kbps

ffmpeg -i "$1" -c:v libvpx-vp9 -b:v "$BITRATE" -vf scale=1280:720 -c:a libopus -b:a 96K "$1-compressed.webm"
