@echo off

set /A MAX_VIDEO_SIZE=187500000
set /A MAX_AUDIO_SIZE=12500000

if "%~1" == "" goto nofile

rem Check if file is video, get duration if it is

for /f "delims=" %%i in ('@ffprobe ^-hide^_banner "%~1" ^-show^_entries format^=duration -v quiet -of csv^=^"p^=0^"') do (
    SET var=%%i
)

if [%var%]==[] goto invalidfile

echo "%~1" is a video file and is %var% seconds long

rem Calculate bitrate

for /f "tokens=1,2 delims=." %%a  in ("%var%") do (
  set first_part=%%a
  set second_part=%%b
)

set /a rounded=%first_part%

set /A VIDEO_BITRATE=%MAX_VIDEO_SIZE% / %rounded%
set /A AUDIO_BITRATE=%MAX_AUDIO_SIZE% / %rounded%
set /A SHOULD_BITRATE=%VIDEO_BITRATE% + %AUDIO_BITRATE%

echo video should have a bitrate of %SHOULD_BITRATE% kbps

ffmpeg -hide_banner -i "%~1" -c:v libvpx-vp9 -row-mt 1 -b:v "%VIDEO_BITRATE%" -pix_fmt yuv420p -vf scale=1280:720 -pass 1 -an -f null NUL && ffmpeg -hide_banner -i "%~1" -c:v libvpx-vp9 -cpu-used 3 -row-mt 1 -b:v "%VIDEO_BITRATE%" -pix_fmt yuv420p -vf scale=1280:720  -c:a libopus -b:a "%AUDIO_BITRATE%" -pass 2 "%~1-compressed.mp4"

goto end

:nofile
echo Error: No video file selected
echo Usage: %0 ^<video-file^>
pause
exit /B 1

:invalidfile
echo Error: "%~1" is not a video file
pause
exit /B 1

:end
echo "Done."
pause
exit /B 0