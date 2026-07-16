@echo off
setlocal enabledelayedexpansion

REM If an argument is passed (drag & drop), use it directly
if "%~1"=="" (
    set /p file_path="Enter the full path of the file (audio or video): "
) else (
    set "file_path=%~1"
)

REM Strip quotes (just in case) and extra spaces
set "file_path=%file_path:"=%"

REM Check if the file exists
if not exist "%file_path%" (
    echo The file does not exist.
    pause
    exit /b
)

REM Extract name, folder and extension
for %%F in ("%file_path%") do set "file_name=%%~nF"
for %%F in ("%file_path%") do set "file_dir=%%~dpF"
for %%F in ("%file_path%") do set "file_ext=%%~xF"

REM Show options
echo Select the format for conversion:
echo 1. MP3 (Audio)
echo 2. MP4 (Video)
echo 3. WAV (Audio)
echo 4. AVI (Video)
echo 5. MKV (Video)
echo 6. AAC (Audio)
echo 7. FLAC (Audio)
echo 8. MOV (Video)
echo 9. WMV (Video)
echo 10. OGG (Audio)
set /p format_choice="Enter your choice (1-10): "

REM Determine format
if "%format_choice%"=="1" set format=mp3
if "%format_choice%"=="2" set format=mp4
if "%format_choice%"=="3" set format=wav
if "%format_choice%"=="4" set format=avi
if "%format_choice%"=="5" set format=mkv
if "%format_choice%"=="6" set format=aac
if "%format_choice%"=="7" set format=flac
if "%format_choice%"=="8" set format=mov
if "%format_choice%"=="9" set format=wmv
if "%format_choice%"=="10" set format=ogg

if not defined format (
    echo Invalid choice! Please select a number between 1 and 10.
    pause
    exit /b
)

REM Build output name (avoid overwriting)
set "output_file=%file_dir%%file_name%.%format%"
set count=1
if exist "%output_file%" (
    :find_new_name
    set "output_file=%file_dir%%file_name%_!count!.%format%"
    if exist "%output_file%" (
        set /a count+=1
        goto find_new_name
    )
)

REM Run FFmpeg
ffmpeg -i "%file_path%" "%output_file%"
echo Conversion complete! File saved as "%output_file%"

pause
