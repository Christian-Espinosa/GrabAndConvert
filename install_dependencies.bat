@echo off
setlocal enabledelayedexpansion
title Install / Update dependencies

echo ==========================================================
echo   INSTALL / UPDATE DEPENDENCIES
echo ==========================================================
echo Checks, installs and updates everything the scripts in this
echo repository need:
echo   - yt-dlp   ^(YouTube / YouTube Music downloads^)
echo   - spotdl   ^(Spotify downloads^)
echo   - ffmpeg   ^(audio / video / image conversion^)
echo   - Deno     ^(JS runtime that yt-dlp needs for YouTube^)
echo.

:: ---------------------------------------------------------------
:: 1) Locate Python / pip
:: ---------------------------------------------------------------
set "PIP_CMD="
py -m pip --version >nul 2>&1 && set "PIP_CMD=py -m pip"
if not defined PIP_CMD (
    python -m pip --version >nul 2>&1 && set "PIP_CMD=python -m pip"
)
if not defined PIP_CMD (
    pip --version >nul 2>&1 && set "PIP_CMD=pip"
)

if not defined PIP_CMD (
    echo [ERROR] Python/pip was not found on this system.
    echo.
    echo Install Python from https://www.python.org/downloads/
    echo and tick the "Add Python to PATH" box during installation.
    echo Then run this script again.
    goto :end
)
echo [OK] pip found: !PIP_CMD!
echo.

:: ---------------------------------------------------------------
:: 2) yt-dlp  (install or update)
:: ---------------------------------------------------------------
echo ---------------- yt-dlp ----------------
!PIP_CMD! install --upgrade yt-dlp
echo.

:: ---------------------------------------------------------------
:: 3) spotdl  (install or update)
:: ---------------------------------------------------------------
echo ---------------- spotdl ----------------
!PIP_CMD! install --upgrade spotdl
echo.

:: ---------------------------------------------------------------
:: 4) Locate the installed executables (pip puts them in Scripts,
::    which is sometimes not on the PATH)
:: ---------------------------------------------------------------
call :find_tool YTDLP_CMD yt-dlp
call :find_tool SPOTDL_CMD spotdl

:: ---------------------------------------------------------------
:: 5) Deno (JavaScript runtime that yt-dlp uses to decode YouTube)
:: ---------------------------------------------------------------
echo ---------------- Deno ----------------
where deno >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Deno is already available on the PATH.
) else if exist "%USERPROFILE%\.spotdl\deno.exe" (
    echo [OK] Deno already installed for spotdl: %USERPROFILE%\.spotdl\deno.exe
) else (
    if defined SPOTDL_CMD (
        echo [INFO] Downloading Deno with spotdl...
        "!SPOTDL_CMD!" --download-deno
    ) else (
        echo [NOTICE] Could not locate spotdl to download Deno.
        echo          Run manually:  spotdl --download-deno
    )
)
echo.

:: ---------------------------------------------------------------
:: 6) ffmpeg
:: ---------------------------------------------------------------
echo ---------------- ffmpeg ----------------
where ffmpeg >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] ffmpeg found on the PATH.
) else (
    echo [NOTICE] ffmpeg not found.
    where winget >nul 2>&1
    if !errorlevel! equ 0 (
        echo [INFO] Trying to install ffmpeg with winget...
        winget install --id Gyan.FFmpeg -e --accept-package-agreements --accept-source-agreements
        echo [INFO] Close and reopen the terminal so ffmpeg is added to the PATH.
    ) else (
        echo Install ffmpeg manually from:
        echo   https://www.gyan.dev/ffmpeg/builds/
        echo and add its "bin" folder to the system PATH.
    )
)
echo.

:: ---------------------------------------------------------------
:: 7) Version summary
:: ---------------------------------------------------------------
echo ==========================================================
echo   VERSION SUMMARY
echo ==========================================================
if defined YTDLP_CMD (
    for /f "tokens=*" %%A in ('"!YTDLP_CMD!" --version 2^>nul') do echo yt-dlp : %%A
) else (
    echo yt-dlp : NOT FOUND
)
if defined SPOTDL_CMD (
    for /f "tokens=*" %%A in ('"!SPOTDL_CMD!" --version 2^>nul') do echo spotdl : %%A
) else (
    echo spotdl : NOT FOUND
)
where ffmpeg >nul 2>&1 && (echo ffmpeg : OK) || (echo ffmpeg : NOT FOUND)
if exist "%USERPROFILE%\.spotdl\deno.exe" (
    echo Deno   : OK ^(spotdl^)
) else (
    where deno >nul 2>&1 && (echo Deno   : OK ^(PATH^)) || (echo Deno   : NOT FOUND)
)
echo ==========================================================
echo All set. You can now use the scripts in this repository.

:end
echo.
pause
exit /b 0

:: ===============================================================
:: Subroutine: finds an executable (yt-dlp / spotdl) on the PATH and
:: in Python's Scripts folders. Usage: call :find_tool VAR name
:: ===============================================================
:find_tool
set "%~1="
where %~2 >nul 2>&1 && set "%~1=%~2"
if defined %~1 goto :eof
for %%V in (315 314 313 312 311 310 39 38 37) do (
    if not defined %~1 (
        if exist "%USERPROFILE%\AppData\Roaming\Python\Python%%V\Scripts\%~2.exe" (
            set "%~1=%USERPROFILE%\AppData\Roaming\Python\Python%%V\Scripts\%~2.exe"
        ) else if exist "%USERPROFILE%\AppData\Local\Programs\Python\Python%%V\Scripts\%~2.exe" (
            set "%~1=%USERPROFILE%\AppData\Local\Programs\Python\Python%%V\Scripts\%~2.exe"
        ) else if exist "C:\Python%%V\Scripts\%~2.exe" (
            set "%~1=C:\Python%%V\Scripts\%~2.exe"
        )
    )
)
goto :eof
