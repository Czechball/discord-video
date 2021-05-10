#!/bin/bash

# 64 000 000 bits (8 MB) / video length (s) = target bitrate (bps)

MAX_VIDEO_SIZE="64000000"

# Check argument

if [[ "$1" == "" ]]; then
	echo "Error: No video file selected"
	echo "Usage: $0 <video-file>"
	exit
fi

# Check if file is video, get duration using ffprobe if it is

DURATION=$(ffprobe -hide_banner -loglevel quiet "$1" -show_entries format=duration -v quiet -of csv="p=0")

if [[ "$DURATION" == "" ]]; then
	echo Error, ffprobe returned no duration. "$1" is possibly not a video file
	exit
fi

echo "$1" is a video file and is "$DURATION" seconds long

# Calculate bitrate

ADJUSTED_DURATION=$(printf "%.0f\n" "$DURATION")
VIDEO_BITRATE=$(( (MAX_VIDEO_SIZE*80/ADJUSTED_DURATION/100)-96000 ))

# Create ffmpeg command

FFMPEG_COMMAND="ffmpeg -hide_banner -i \"$1\" -c:v libvpx-vp9 -b:v \"$VIDEO_BITRATE\" -vf scale=1280:720 -c:a libopus -b:a 96K \"$1-compressed.webm\""
echo
echo Launching command:
echo "$FFMPEG_COMMAND"
sleep 2
eval "$FFMPEG_COMMAND"
