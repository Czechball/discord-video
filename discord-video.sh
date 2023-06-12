#!/bin/bash

# 200 000 000 bits / video length = target bitrate

MAX_VIDEO_SIZE="187500000"
#MAX_AUDIO_SIZE="12500000"

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

echo "$1" is a video file and is "$DURATION" seconds long

WIDTH=$(ffprobe -hide_banner "$1" -v quiet -show_entries stream=width -of csv=p=0)
HEIGHT=$(ffprobe -hide_banner "$1" -v quiet -show_entries stream=height -of csv=p=0)
ROTATION=$(ffprobe -hide_banner "$1" -v quiet -show_entries stream_side_data=rotation -of csv=p=0)

WIDTH=${WIDTH%%,}
HEIGHT=${HEIGHT%%,}
ROTATION=${ROTATION%%,}
[ "$ROTATION" ] || ROTATION=0

if [ "$WIDTH" -gt "$HEIGHT" ] && [ "${ROTATION##-}" != 90 ]; then
  [ "$WIDTH" -gt 1280 ] && WIDTH=1280
  HEIGHT=-1
  echo "$1 is horizontal video; scaling to $WIDTH x $HEIGHT"
else
  WIDTH=-1
  [ "$HEIGHT" -gt 1280 ] && HEIGHT=1280
  echo "$1 is vertical video; scaling to $WIDTH x $HEIGHT"
fi

# Calculate bitrate

ADJUSTED_DURATION=$(printf "%.0f\n" "$DURATION")
VIDEO_BITRATE=$((MAX_VIDEO_SIZE / ADJUSTED_DURATION))
#AUDIO_BITRATE=$(echo $((MAX_AUDIO_SIZE / ADJUSTED_DURATION)))

set -e

ffmpeg \
  -hide_banner \
  -i "$1" \
  -c:v libvpx-vp9 \
  -row-mt 1 \
  -b:v "$VIDEO_BITRATE" \
  -pix_fmt yuv420p \
  -vf scale=$WIDTH:$HEIGHT \
  -pass 1 \
  -an \
  -f null \
  /dev/null

ffmpeg \
  -hide_banner \
  -i "$1" \
  -c:v libvpx-vp9 \
  -cpu-used 3 \
  -row-mt 1 \
  -b:v "$VIDEO_BITRATE" \
  -pix_fmt yuv420p \
  -vf scale=$WIDTH:$HEIGHT \
  -pass 2 \
  "$1-compressed.mp4"
