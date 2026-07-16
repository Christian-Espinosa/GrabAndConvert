@echo off
setlocal enabledelayedexpansion
title Instalar / Actualizar dependencias

echo ==========================================================
echo   INSTALAR / ACTUALIZAR DEPENDENCIAS
echo ==========================================================
echo Comprueba, instala y actualiza todo lo que necesitan los
echo scripts de este repositorio:
echo   - yt-dlp   ^(descargas de YouTube / YouTube Music^)
echo   - spotdl   ^(descargas de Spotify^)
echo   - ffmpeg   ^(conversion de audio / video / imagen^)
echo   - Deno     ^(motor JS que yt-dlp necesita para YouTube^)
echo.

:: ---------------------------------------------------------------
:: 1) Localizar Python / pip
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
    echo [ERROR] No se encontro Python/pip en el sistema.
    echo.
    echo Instala Python desde https://www.python.org/downloads/
    echo y marca la casilla "Add Python to PATH" durante la instalacion.
    echo Despues vuelve a ejecutar este script.
    goto :end
)
echo [OK] pip encontrado: !PIP_CMD!
echo.

:: ---------------------------------------------------------------
:: 2) yt-dlp  (instalar o actualizar)
:: ---------------------------------------------------------------
echo ---------------- yt-dlp ----------------
!PIP_CMD! install --upgrade yt-dlp
echo.

:: ---------------------------------------------------------------
:: 3) spotdl  (instalar o actualizar)
:: ---------------------------------------------------------------
echo ---------------- spotdl ----------------
!PIP_CMD! install --upgrade spotdl
echo.

:: ---------------------------------------------------------------
:: 4) Localizar los ejecutables instalados (pip los pone en Scripts,
::    que a veces no esta en el PATH)
:: ---------------------------------------------------------------
call :find_tool YTDLP_CMD yt-dlp
call :find_tool SPOTDL_CMD spotdl

:: ---------------------------------------------------------------
:: 5) Deno (motor JavaScript que yt-dlp usa para descifrar YouTube)
:: ---------------------------------------------------------------
echo ---------------- Deno ----------------
where deno >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Deno ya esta disponible en el PATH.
) else if exist "%USERPROFILE%\.spotdl\deno.exe" (
    echo [OK] Deno ya instalado para spotdl: %USERPROFILE%\.spotdl\deno.exe
) else (
    if defined SPOTDL_CMD (
        echo [INFO] Descargando Deno con spotdl...
        "!SPOTDL_CMD!" --download-deno
    ) else (
        echo [AVISO] No se pudo localizar spotdl para descargar Deno.
        echo         Ejecuta manualmente:  spotdl --download-deno
    )
)
echo.

:: ---------------------------------------------------------------
:: 6) ffmpeg
:: ---------------------------------------------------------------
echo ---------------- ffmpeg ----------------
where ffmpeg >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] ffmpeg encontrado en el PATH.
) else (
    echo [AVISO] ffmpeg no encontrado.
    where winget >nul 2>&1
    if !errorlevel! equ 0 (
        echo [INFO] Intentando instalar ffmpeg con winget...
        winget install --id Gyan.FFmpeg -e --accept-package-agreements --accept-source-agreements
        echo [INFO] Cierra y vuelve a abrir la terminal para que ffmpeg quede en el PATH.
    ) else (
        echo Instala ffmpeg manualmente desde:
        echo   https://www.gyan.dev/ffmpeg/builds/
        echo y agrega su carpeta "bin" al PATH del sistema.
    )
)
echo.

:: ---------------------------------------------------------------
:: 7) Resumen de versiones
:: ---------------------------------------------------------------
echo ==========================================================
echo   RESUMEN DE VERSIONES
echo ==========================================================
if defined YTDLP_CMD (
    for /f "tokens=*" %%A in ('"!YTDLP_CMD!" --version 2^>nul') do echo yt-dlp : %%A
) else (
    echo yt-dlp : NO ENCONTRADO
)
if defined SPOTDL_CMD (
    for /f "tokens=*" %%A in ('"!SPOTDL_CMD!" --version 2^>nul') do echo spotdl : %%A
) else (
    echo spotdl : NO ENCONTRADO
)
where ffmpeg >nul 2>&1 && (echo ffmpeg : OK) || (echo ffmpeg : NO ENCONTRADO)
if exist "%USERPROFILE%\.spotdl\deno.exe" (
    echo Deno   : OK ^(spotdl^)
) else (
    where deno >nul 2>&1 && (echo Deno   : OK ^(PATH^)) || (echo Deno   : NO ENCONTRADO)
)
echo ==========================================================
echo Todo listo. Ya puedes usar los scripts del repositorio.

:end
echo.
pause
exit /b 0

:: ===============================================================
:: Subrutina: busca un ejecutable (yt-dlp / spotdl) en PATH y en
:: las carpetas Scripts de Python. Uso: call :find_tool VAR nombre
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
