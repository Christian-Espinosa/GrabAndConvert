@echo off
setlocal enabledelayedexpansion

:: ================================================================
:: DESCARGADOR MULTIPLATAFORMA (YouTube / YouTube Music / Spotify)
:: - yt-dlp para YouTube y YouTube Music (MP3 o MP4)
:: - spotdl para Spotify (solo audio MP3)
:: - Espera entre elementos SOLO cuando es una lista
:: - NO comprueba actualizaciones (usa instalar_dependencias.bat manualmente)
:: ================================================================

set "EXIT_CODE=0"

echo ========================================
echo   DESCARGADOR DE MUSICA / VIDEO
echo ========================================
echo.

:: ---------------------------------------------------------------
:: 1) Localizar yt-dlp (rapido, sin ejecutar --version)
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
:: 1b) Localizar spotdl (para Spotify)
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
:: 1c) Localizar un runtime de JavaScript (Deno) para yt-dlp.
:: YouTube ahora requiere ejecutar un reto JS; sin runtime a veces
:: solo se obtiene el audio. Reutilizamos el Deno de spotdl si existe.
:: ---------------------------------------------------------------
set "DENO_ARG="
where deno >nul 2>&1 && set "DENO_ARG=--js-runtimes deno"
if not defined DENO_ARG if exist "%USERPROFILE%\.spotdl\deno.exe" set "DENO_ARG=--js-runtimes deno:%USERPROFILE%\.spotdl\deno.exe"

:: ---------------------------------------------------------------
:: 2) Pedir URL
:: ---------------------------------------------------------------
set /p "URL=Pega la URL (cancion, video, lista o album): "
if "!URL!"=="" (
    echo [ERROR] No se proporciono URL
    set "EXIT_CODE=1"
    goto :end
)

:: Limpiar: si hay texto pegado delante, quedarnos desde "https"
if not "!URL!"=="!URL:https=!" set "URL=https!URL:*https=!"
echo [INFO] URL: !URL!
echo.

:: ---------------------------------------------------------------
:: 3) Detectar plataforma (por substring, seguro con & en la URL)
:: ---------------------------------------------------------------
set "PLATFORM=youtube"
if not "!URL!"=="!URL:open.spotify.com=!" set "PLATFORM=spotify"
if not "!URL!"=="!URL:spotify:=!" set "PLATFORM=spotify"

if "!PLATFORM!"=="spotify" (
    echo [INFO] Plataforma detectada: Spotify (solo audio MP3^)
) else (
    echo [INFO] Plataforma detectada: YouTube / YouTube Music / otros
)
echo.

:: ---------------------------------------------------------------
:: 4) Comprobar que existe la herramienta necesaria
:: ---------------------------------------------------------------
if "!PLATFORM!"=="spotify" (
    if not defined SPOTDL_CMD (
        echo [ERROR] Spotify necesita 'spotdl' y no esta instalado.
        echo Instalalo con:  pip install spotdl
        echo (spotdl tambien requiere yt-dlp y ffmpeg^)
        set "EXIT_CODE=1"
        goto :end
    )
) else (
    if not defined YTDLP_CMD (
        echo [ERROR] yt-dlp no esta instalado o no se encuentra.
        echo Instalalo con:  pip install yt-dlp
        echo O descarga desde: https://github.com/yt-dlp/yt-dlp
        set "EXIT_CODE=1"
        goto :end
    )
)

:: ---------------------------------------------------------------
:: 5) Detectar si es una LISTA / ALBUM
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

:: Confirmar cuando parece lista (por si es un video suelto dentro de una lista)
if "!IS_PLAYLIST!"=="1" (
    set /p "CONFIRM=Parece una LISTA. Descargar todos los elementos? (S/N, Enter=S): "
    if /i "!CONFIRM!"=="N" set "IS_PLAYLIST=0"
    echo.
)

:: ---------------------------------------------------------------
:: 6) Elegir formato (Spotify se fuerza a MP3)
:: ---------------------------------------------------------------
if "!PLATFORM!"=="spotify" (
    set "FORMATO=mp3"
    echo [INFO] Spotify solo permite audio: formato MP3
) else (
    echo Selecciona el formato:
    echo   1. MP3 ^(solo audio^)
    echo   2. MP4 ^(video^)
    set /p "OPT=Tu eleccion (1 o 2, Enter=1): "
    if "!OPT!"=="2" (
        set "FORMATO=mp4"
    ) else (
        set "FORMATO=mp3"
    )
    echo Formato seleccionado: !FORMATO!
)
echo.

:: Calidad de video (solo MP4). Por defecto 1080p.
set "VQ=1080"
if /i "!FORMATO!"=="mp4" (
    echo Calidad maxima de video:
    echo   1. 2160p ^(4K^)
    echo   2. 1440p ^(2K^)
    echo   3. 1080p ^(Full HD^) [por defecto]
    echo   4. 720p ^(HD^)
    echo   5. 480p
    set /p "VOPT=Tu eleccion (1-5, Enter=3): "
    if "!VOPT!"=="1" set "VQ=2160"
    if "!VOPT!"=="2" set "VQ=1440"
    if "!VOPT!"=="3" set "VQ=1080"
    if "!VOPT!"=="4" set "VQ=720"
    if "!VOPT!"=="5" set "VQ=480"
    echo Calidad seleccionada: !VQ!p ^(o la mas cercana disponible^)
    echo.
)

:: ---------------------------------------------------------------
:: 7) Carpeta de destino
:: ---------------------------------------------------------------
set /p "DOWNLOAD_PATH=Carpeta de destino (Enter = carpeta actual): "
if "!DOWNLOAD_PATH!"=="" set "DOWNLOAD_PATH=."
if not exist "!DOWNLOAD_PATH!" mkdir "!DOWNLOAD_PATH!" 2>nul
echo.

:: ---------------------------------------------------------------
:: 8) Segundos de espera (solo si es lista)
:: ---------------------------------------------------------------
set "SLEEP=0"
if "!IS_PLAYLIST!"=="1" (
    set /p "SLEEP=Segundos de espera entre elementos (Enter = 5): "
    if "!SLEEP!"=="" set "SLEEP=5"
    echo [INFO] Se esperara !SLEEP!s entre elementos para evitar bloqueos.
    echo.
)

echo ========================================
echo   Iniciando descarga...
echo ========================================
echo.

:: ===============================================================
:: DESCARGA CON SPOTDL (Spotify)
:: ===============================================================
if "!PLATFORM!"=="spotify" (
    echo [INFO] Descargando desde Spotify con spotdl...
    echo [INFO] Proveedores: youtube-music, youtube, soundcloud (con reintentos^)
    "!SPOTDL_CMD!" download "!URL!" --format mp3 --bitrate 320k --audio youtube-music youtube soundcloud --max-retries 3 --yt-dlp-args "--retries 5 --fragment-retries 5" --print-errors --output "!DOWNLOAD_PATH!\{artists} - {title}.{output-ext}"
    set "DOWNLOAD_ERROR=!errorlevel!"
    goto :result
)

:: ===============================================================
:: DESCARGA CON YT-DLP (YouTube / YouTube Music / otros)
:: ===============================================================

:: Opciones de lista vs elemento unico
if "!IS_PLAYLIST!"=="1" (
    set "PL_OPTS=--yes-playlist --sleep-interval !SLEEP! --ignore-errors"
    set "OUT_TMPL=!DOWNLOAD_PATH!\%%(playlist_index)s - %%(title)s.%%(ext)s"
) else (
    set "PL_OPTS=--no-playlist"
    set "OUT_TMPL=!DOWNLOAD_PATH!\%%(title)s.%%(ext)s"
)

:: Clientes por defecto de yt-dlp (dan acceso a formatos DASH de alta calidad).
:: Nota: NO forzamos player_client=android porque limita el video a 360p.
set "COMMON=--no-warnings !PL_OPTS! !DENO_ARG!"

if /i "!FORMATO!"=="mp3" (
    echo Descargando audio MP3...
    "!YTDLP_CMD!" !COMMON! -f "bestaudio/best" -x --audio-format mp3 --audio-quality 0 --output "!OUT_TMPL!" "!URL!"
    set "DOWNLOAD_ERROR=!errorlevel!"
) else (
    echo Descargando video MP4 ^(hasta !VQ!p^)...
    "!YTDLP_CMD!" !COMMON! -f "bv*[height<=!VQ!][ext=mp4]+ba[ext=m4a]/bv*[height<=!VQ!]+ba/b[height<=!VQ!]/bv*+ba/b" --merge-output-format mp4 --output "!OUT_TMPL!" "!URL!"
    set "DOWNLOAD_ERROR=!errorlevel!"
)

:: Reintento con formato alternativo SOLO para elemento unico.
:: En listas, --ignore-errors ya gestiona los fallos por elemento, asi que
:: no reintentamos toda la lista (evita volver a descargar lo ya bajado).
if "!IS_PLAYLIST!"=="0" if !DOWNLOAD_ERROR! neq 0 (
    echo.
    echo [INFO] Primer intento fallo ^(codigo !DOWNLOAD_ERROR!^). Probando alternativa...
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
    echo [EXITO] Descarga completada
) else (
    if "!IS_PLAYLIST!"=="1" (
        echo [AVISO] Lista finalizada. Algunos elementos se omitieron
        echo         ^(no disponibles, privados o restringidos^). El resto se descargo.
    ) else (
        echo [ERROR] La descarga fallo ^(codigo !DOWNLOAD_ERROR!^)
        echo.
        echo Posibles soluciones:
        echo   1. Verifica que la URL sea valida
        echo   2. Actualiza las librerias ejecutando: instalar_dependencias.bat
        echo   3. El contenido puede estar restringido o no disponible
        echo   4. Revisa tu conexion a internet
        set "EXIT_CODE=1"
    )
)

:end
echo.
echo ========================================
echo   Resumen
echo ========================================
if defined PLATFORM      echo Plataforma: !PLATFORM!
if defined URL           echo URL: !URL!
if defined FORMATO        echo Formato: !FORMATO!
if /i "!FORMATO!"=="mp4"  echo Calidad: hasta !VQ!p
if defined DOWNLOAD_PATH  echo Carpeta: !DOWNLOAD_PATH!
if "!IS_PLAYLIST!"=="1"   echo Lista: si (espera !SLEEP!s^)
if defined DOWNLOAD_ERROR echo Codigo final: !DOWNLOAD_ERROR!
echo ========================================
echo.
pause
exit /b %EXIT_CODE%
