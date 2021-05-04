@echo off

set /A MAX_SIZE=64000000

if [%1]==[] goto nofile

rem Check if file is video, get duration if it is

for /f "delims=" %%i in ('@ffprobe ^-hide^_banner "%1" ^-show^_entries format^=duration -v quiet -of csv^=^"p^=0^"') do (
    SET var=%%i
)

if [%var%]==[] goto invalidfile

echo "%1" is a video file and is %var% seconds long

rem Calculate bitrate

for /f "tokens=1,2 delims=." %%a  in ("%var%") do (
  set first_part=%%a
  set second_part=%%b
)

set /a rounded=%first_part%

set /A BITRATE=%MAX_SIZE% / %rounded% * 75 / 100
set /A SHOULD_BITRATE=(%MAX_SIZE% / %rounded%)/1000

echo video should have a bitrate of %SHOULD_BITRATE% kbps

ffmpeg -i "%1" -c:v libvpx-vp9 -b:v "%BITRATE%" -c:a libopus -b:a 96K "%1-compressed.webm"

pause
goto end

:nofile
echo Error: No video file selected
echo Usage: %0 ^<video-file^>
exit /B 1

:invalidfile
echo Error: "%1" is not a video file
exit /B 1

:end
exit /B 0
