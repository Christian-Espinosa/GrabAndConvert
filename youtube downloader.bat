@echo off
setlocal enabledelayedexpansion

:: ================================================================
:: MULTI-PLATFORM DOWNLOADER (YouTube / YouTube Music / Spotify)
:: - yt-dlp for YouTube and YouTube Music (MP3 or MP4)
:: - spotdl for Spotify (audio only, MP3)
:: - Waits between items ONLY when it is a playlist
:: - Does NOT check for updates (run install_dependencies.bat manually)
:: ================================================================

set "EXIT_CODE=0"

echo ========================================
echo   MUSIC / VIDEO DOWNLOADER
echo ========================================
echo.

:: ---------------------------------------------------------------
:: 1) Locate yt-dlp (fast, without running --version)
:: ---------------------------------------------------------------
set "YTDLP_CMD="
where yt-dlp >nul 2>&1 && set "YTDLP_CMD=yt-dlp"
if not defined YTDLP_CMD (
    for %%V in (315 314 313 312 311 310 39 38 37) do (
        if not defined YTDLP_CMD (
            if exist "%USERPROFILE%\AppData\Roaming\Python\Python%%V\Scripts\yt-dlp.exe" (
                set "YTDLP_CMD=%USERPROFILE%\AppData\Roaming\Python\Python%%V\Scripts\yt-dlp.exe"
            ) else if exist "%USERPROFILE%\AppData\Local\Programs\Python\Python%%V\Scripts\yt-dlp.exe" (
                set "YTDLP_CMD=%USERPROFILE%\AppData\Local\Programs\Python\Python%%V\Scripts\yt-dlp.exe"
            ) else if exist "C:\Python%%V\Scripts\yt-dlp.exe" (
                set "YTDLP_CMD=C:\Python%%V\Scripts\yt-dlp.exe"
            )
        )
    )
)

:: ---------------------------------------------------------------
:: 1b) Locate spotdl (for Spotify)
:: ---------------------------------------------------------------
set "SPOTDL_CMD="
where spotdl >nul 2>&1 && set "SPOTDL_CMD=spotdl"
if not defined SPOTDL_CMD (
    for %%V in (315 314 313 312 311 310 39 38 37) do (
        if not defined SPOTDL_CMD (
            if exist "%USERPROFILE%\AppData\Roaming\Python\Python%%V\Scripts\spotdl.exe" (
                set "SPOTDL_CMD=%USERPROFILE%\AppData\Roaming\Python\Python%%V\Scripts\spotdl.exe"
            ) else if exist "%USERPROFILE%\AppData\Local\Programs\Python\Python%%V\Scripts\spotdl.exe" (
                set "SPOTDL_CMD=%USERPROFILE%\AppData\Local\Programs\Python\Python%%V\Scripts\spotdl.exe"
            ) else if exist "C:\Python%%V\Scripts\spotdl.exe" (
                set "SPOTDL_CMD=C:\Python%%V\Scripts\spotdl.exe"
            )
        )
    )
)

:: ---------------------------------------------------------------
:: 1c) Locate a JavaScript runtime (Deno) for yt-dlp.
:: YouTube now requires solving a JS challenge; without a runtime
:: sometimes only the audio is available. Reuse spotdl's Deno if present.
:: ---------------------------------------------------------------
set "DENO_ARG="
where deno >nul 2>&1 && set "DENO_ARG=--js-runtimes deno"
if not defined DENO_ARG if exist "%USERPROFILE%\.spotdl\deno.exe" set "DENO_ARG=--js-runtimes deno:%USERPROFILE%\.spotdl\deno.exe"

:: ---------------------------------------------------------------
:: 2) Ask for the URL
:: ---------------------------------------------------------------
set /p "URL=Paste the URL (song, video, playlist or album): "
if "!URL!"=="" (
    echo [ERROR] No URL provided
    set "EXIT_CODE=1"
    goto :end
)

:: Clean up: if there is text pasted before it, keep from "https" onward
if not "!URL!"=="!URL:https=!" set "URL=https!URL:*https=!"
echo [INFO] URL: !URL!
echo.

:: ---------------------------------------------------------------
:: 3) Detect platform (by substring, safe with & in the URL)
:: ---------------------------------------------------------------
set "PLATFORM=youtube"
if not "!URL!"=="!URL:open.spotify.com=!" set "PLATFORM=spotify"
if not "!URL!"=="!URL:spotify:=!" set "PLATFORM=spotify"

if "!PLATFORM!"=="spotify" (
    echo [INFO] Detected platform: Spotify ^(audio only, MP3^)
) else (
    echo [INFO] Detected platform: YouTube / YouTube Music / other
)
echo.

:: ---------------------------------------------------------------
:: 4) Check that the required tool is available
:: ---------------------------------------------------------------
if "!PLATFORM!"=="spotify" (
    if not defined SPOTDL_CMD (
        echo [ERROR] Spotify requires 'spotdl' and it is not installed.
        echo Install it with:  pip install spotdl
        echo ^(spotdl also requires yt-dlp and ffmpeg^)
        set "EXIT_CODE=1"
        goto :end
    )
) else (
    if not defined YTDLP_CMD (
        echo [ERROR] yt-dlp is not installed or could not be found.
        echo Install it with:  pip install yt-dlp
        echo Or download it from: https://github.com/yt-dlp/yt-dlp
        set "EXIT_CODE=1"
        goto :end
    )
)

:: ---------------------------------------------------------------
:: 5) Detect whether it is a PLAYLIST / ALBUM
:: ---------------------------------------------------------------
set "IS_PLAYLIST=0"
if "!PLATFORM!"=="spotify" (
    if not "!URL!"=="!URL:/playlist/=!" set "IS_PLAYLIST=1"
    if not "!URL!"=="!URL:/album/=!" set "IS_PLAYLIST=1"
    if not "!URL!"=="!URL::playlist:=!" set "IS_PLAYLIST=1"
    if not "!URL!"=="!URL::album:=!" set "IS_PLAYLIST=1"
) else (
    if not "!URL!"=="!URL:list=!" set "IS_PLAYLIST=1"
    if not "!URL!"=="!URL:/sets/=!" set "IS_PLAYLIST=1"
    if not "!URL!"=="!URL:/channel/=!" set "IS_PLAYLIST=1"
    if not "!URL!"=="!URL:/@=!" set "IS_PLAYLIST=1"
)

:: Confirm when it looks like a playlist (in case it is a single video inside a list)
if "!IS_PLAYLIST!"=="1" (
    set /p "CONFIRM=This looks like a PLAYLIST. Download all items? (Y/N, Enter=Y): "
    if /i "!CONFIRM!"=="N" set "IS_PLAYLIST=0"
    echo.
)

:: ---------------------------------------------------------------
:: 6) Choose format (Spotify is forced to MP3)
:: ---------------------------------------------------------------
if "!PLATFORM!"=="spotify" (
    set "FORMATO=mp3"
    echo [INFO] Spotify only allows audio: MP3 format
) else (
    echo Select the format:
    echo   1. MP3 ^(audio only^)
    echo   2. MP4 ^(video^)
    set /p "OPT=Your choice (1 or 2, Enter=1): "
    if "!OPT!"=="2" (
        set "FORMATO=mp4"
    ) else (
        set "FORMATO=mp3"
    )
    echo Selected format: !FORMATO!
)
echo.

:: Video quality (MP4 only). Default 1080p.
set "VQ=1080"
if /i "!FORMATO!"=="mp4" (
    echo Maximum video quality:
    echo   1. 2160p ^(4K^)
    echo   2. 1440p ^(2K^)
    echo   3. 1080p ^(Full HD^) [default]
    echo   4. 720p ^(HD^)
    echo   5. 480p
    set /p "VOPT=Your choice (1-5, Enter=3): "
    if "!VOPT!"=="1" set "VQ=2160"
    if "!VOPT!"=="2" set "VQ=1440"
    if "!VOPT!"=="3" set "VQ=1080"
    if "!VOPT!"=="4" set "VQ=720"
    if "!VOPT!"=="5" set "VQ=480"
    echo Selected quality: !VQ!p ^(or the closest available^)
    echo.
)

:: ---------------------------------------------------------------
:: 7) Destination folder
:: ---------------------------------------------------------------
set /p "DOWNLOAD_PATH=Destination folder (Enter = current folder): "
if "!DOWNLOAD_PATH!"=="" set "DOWNLOAD_PATH=."
if not exist "!DOWNLOAD_PATH!" mkdir "!DOWNLOAD_PATH!" 2>nul
echo.

:: ---------------------------------------------------------------
:: 8) Wait seconds (only if it is a playlist)
:: ---------------------------------------------------------------
set "SLEEP=0"
if "!IS_PLAYLIST!"=="1" (
    set /p "SLEEP=Seconds to wait between items (Enter = 5): "
    if "!SLEEP!"=="" set "SLEEP=5"
    echo [INFO] Will wait !SLEEP!s between items to avoid rate limits.
    echo.
)

echo ========================================
echo   Starting download...
echo ========================================
echo.

:: ===============================================================
:: DOWNLOAD WITH SPOTDL (Spotify)
:: ===============================================================
if "!PLATFORM!"=="spotify" (
    echo [INFO] Downloading from Spotify with spotdl...
    echo [INFO] Providers: youtube-music, youtube, soundcloud ^(with retries^)
    "!SPOTDL_CMD!" download "!URL!" --format mp3 --bitrate 320k --audio youtube-music youtube soundcloud --max-retries 3 --yt-dlp-args "--retries 5 --fragment-retries 5" --print-errors --output "!DOWNLOAD_PATH!\{artists} - {title}.{output-ext}"
    set "DOWNLOAD_ERROR=!errorlevel!"
    goto :result
)

:: ===============================================================
:: DOWNLOAD WITH YT-DLP (YouTube / YouTube Music / other)
:: ===============================================================

:: Playlist vs single item options
if "!IS_PLAYLIST!"=="1" (
    set "PL_OPTS=--yes-playlist --sleep-interval !SLEEP! --ignore-errors"
    set "OUT_TMPL=!DOWNLOAD_PATH!\%%(playlist_index)s - %%(title)s.%%(ext)s"
) else (
    set "PL_OPTS=--no-playlist"
    set "OUT_TMPL=!DOWNLOAD_PATH!\%%(title)s.%%(ext)s"
)

:: Default yt-dlp clients (give access to high-quality DASH formats).
:: Note: we do NOT force player_client=android because it caps video to 360p.
set "COMMON=--no-warnings !PL_OPTS! !DENO_ARG!"

if /i "!FORMATO!"=="mp3" (
    echo Downloading MP3 audio...
    "!YTDLP_CMD!" !COMMON! -f "bestaudio/best" -x --audio-format mp3 --audio-quality 0 --output "!OUT_TMPL!" "!URL!"
    set "DOWNLOAD_ERROR=!errorlevel!"
) else (
    echo Downloading MP4 video ^(up to !VQ!p^)...
    "!YTDLP_CMD!" !COMMON! -f "bv*[height<=!VQ!][ext=mp4]+ba[ext=m4a]/bv*[height<=!VQ!]+ba/b[height<=!VQ!]/bv*+ba/b" --merge-output-format mp4 --output "!OUT_TMPL!" "!URL!"
    set "DOWNLOAD_ERROR=!errorlevel!"
)

:: Retry with an alternative format ONLY for a single item.
:: For playlists, --ignore-errors already handles per-item failures, so we do
:: not retry the whole playlist (this avoids re-downloading what is already done).
if "!IS_PLAYLIST!"=="0" if !DOWNLOAD_ERROR! neq 0 (
    echo.
    echo [INFO] First attempt failed ^(code !DOWNLOAD_ERROR!^). Trying an alternative...
    echo.
    if /i "!FORMATO!"=="mp3" (
        "!YTDLP_CMD!" !COMMON! -f "bestaudio" -x --audio-format mp3 --audio-quality 0 --output "!OUT_TMPL!" "!URL!"
        set "DOWNLOAD_ERROR=!errorlevel!"
    ) else (
        "!YTDLP_CMD!" !COMMON! -f "b[height<=!VQ!]/best" --merge-output-format mp4 --output "!OUT_TMPL!" "!URL!"
        set "DOWNLOAD_ERROR=!errorlevel!"
    )
)

:result
echo.
if !DOWNLOAD_ERROR! equ 0 (
    echo [SUCCESS] Download completed
) else (
    if "!IS_PLAYLIST!"=="1" (
        echo [NOTICE] Playlist finished. Some items were skipped
        echo          ^(unavailable, private or restricted^). The rest were downloaded.
    ) else (
        echo [ERROR] Download failed ^(code !DOWNLOAD_ERROR!^)
        echo.
        echo Possible fixes:
        echo   1. Check that the URL is valid
        echo   2. Update the libraries by running: install_dependencies.bat
        echo   3. The content may be restricted or unavailable
        echo   4. Check your internet connection
        set "EXIT_CODE=1"
    )
)

:end
echo.
echo ========================================
echo   Summary
echo ========================================
if defined PLATFORM      echo Platform: !PLATFORM!
if defined URL           echo URL: !URL!
if defined FORMATO        echo Format: !FORMATO!
if /i "!FORMATO!"=="mp4"  echo Quality: up to !VQ!p
if defined DOWNLOAD_PATH  echo Folder: !DOWNLOAD_PATH!
if "!IS_PLAYLIST!"=="1"   echo Playlist: yes (wait !SLEEP!s^)
if defined DOWNLOAD_ERROR echo Final code: !DOWNLOAD_ERROR!
echo ========================================
echo.
pause
exit /b %EXIT_CODE%
