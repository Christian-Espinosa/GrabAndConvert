# Scripts de descarga y conversión multimedia (Windows)

Colección de scripts `.bat` para **Windows** pensados para descargar música/vídeo y convertir archivos multimedia de forma rápida y sencilla, sin necesidad de programas con interfaz.

Todo funciona por menús interactivos en la consola. Están construidos sobre tres herramientas de código abierto muy conocidas: [yt-dlp](https://github.com/yt-dlp/yt-dlp), [spotDL](https://github.com/spotDL/spotify-downloader) y [FFmpeg](https://ffmpeg.org/).

> Uso responsable: descarga únicamente contenido sobre el que tengas derechos o que permita su descarga. Respeta los términos de servicio de cada plataforma y la legislación de tu país.

---

## Contenido del repositorio

| Script | Para qué sirve |
|---|---|
| `youtube downloader.bat` | Descarga canciones, vídeos, listas y álbumes de **YouTube**, **YouTube Music** y **Spotify** en MP3 o MP4. |
| `Format VIDEO.bat` | Convierte archivos de **audio o vídeo** entre formatos (mp3, mp4, wav, mkv, flac, etc.). |
| `Format IMG.bat` | Convierte **imágenes** entre formatos (jpg, png, webp, gif, etc.). |
| `instalar_dependencias.bat` | Comprueba, **instala y actualiza** todas las librerías que necesitan los scripts. |

---

## Requisitos

- **Windows** con `cmd` (los scripts son archivos `.bat`).
- **Python 3** (incluye `pip`) — necesario para instalar `yt-dlp` y `spotdl`.
  - Descárgalo desde [python.org](https://www.python.org/downloads/) y marca **"Add Python to PATH"** durante la instalación.
- El resto de dependencias (`yt-dlp`, `spotdl`, `ffmpeg`, `Deno`) las instala automáticamente `instalar_dependencias.bat`.

### Instalación rápida

1. Instala Python (ver arriba).
2. Ejecuta **`instalar_dependencias.bat`** (doble clic).

Eso deja el equipo listo: instala yt-dlp, spotdl, ffmpeg (vía winget si está disponible) y Deno, y muestra un resumen de versiones.

---

## `youtube downloader.bat`

Descarga contenido de **YouTube**, **YouTube Music** y **Spotify**.

### Qué hace

- **Detecta la plataforma** automáticamente por la URL:
  - **YouTube / YouTube Music** → usa `yt-dlp` (permite MP3 o MP4).
  - **Spotify** → usa `spotdl`. Spotify solo permite **audio (MP3)**; el vídeo no está disponible, así que se fuerza a MP3.
- Acepta una **canción/vídeo suelto** o una **lista/álbum**.
  - Si detecta una lista, **pregunta** si quieres descargarla entera (por si es un vídeo suelto dentro de una lista).
  - **Solo en listas**, aplica una **espera de X segundos** entre elementos (configurable, 5 por defecto) para evitar bloqueos de la plataforma. Una sola canción se descarga sin espera.
- Permite elegir **MP3** (solo audio) o **MP4** (vídeo).
  - Para **MP4**, puedes elegir la **calidad máxima**: 2160p (4K), 1440p (2K), **1080p (por defecto)**, 720p o 480p. Descarga esa resolución o la más cercana por debajo.
- **Limpia la URL** automáticamente: quita el texto que pegues por delante (p. ej. "Escucha esta lista: ...") y soporta URLs con `&` (parámetros como `?si=...&utm_source=...`).
- No comprueba actualizaciones al arrancar (es ágil). Si algo falla, actualiza con `instalar_dependencias.bat`.

### Resiliencia

- Los vídeos de MP4 se prefieren en **H.264 + AAC** (máxima compatibilidad con reproductores y software de DJ), con reserva a lo mejor disponible.
- Usa **Deno** (detectado automáticamente) para resolver el reto JavaScript que YouTube exige; sin él, a veces solo se obtendría el audio.
- Si un formato da error 403, **reintenta automáticamente** con un stream alternativo (HLS).
- En listas usa `--ignore-errors`: si un elemento no está disponible, lo omite y continúa con el resto.

### Uso

1. Ejecuta `youtube downloader.bat`.
2. Pega la **URL** (canción, vídeo, lista o álbum).
3. Si es una lista, confirma si quieres bajarla entera.
4. Elige **formato** (MP3/MP4) y, en MP4, la **calidad**.
5. Indica la **carpeta** de destino (Enter = carpeta actual).
6. En listas, indica los **segundos de espera** entre elementos.

Ejemplos de URLs válidas:

- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- `https://music.youtube.com/watch?v=VIDEO_ID&si=...`
- `https://music.youtube.com/playlist?list=PLAYLIST_ID`
- `https://open.spotify.com/track/...`
- `https://open.spotify.com/playlist/...` / `https://open.spotify.com/album/...`

---

## `Format VIDEO.bat`

Convierte archivos de **audio o vídeo** de un formato a otro usando FFmpeg.

### Qué hace

- Admite la ruta del archivo de dos formas:
  - **Arrastrando y soltando** el archivo sobre el `.bat` (drag & drop), o
  - **pegando la ruta** cuando la pida.
- Formatos de salida disponibles:
  - Audio: **MP3, WAV, AAC, FLAC, OGG**
  - Vídeo: **MP4, AVI, MKV, MOV, WMV**
- Si ya existe un archivo con el mismo nombre, **no lo sobrescribe**: crea `nombre_1`, `nombre_2`, etc.

### Uso

1. Arrastra un archivo sobre `Format VIDEO.bat` (o ejecútalo y pega la ruta).
2. Elige el número del formato de salida (1-10).
3. El archivo convertido se guarda en la **misma carpeta** que el original.

---

## `Format IMG.bat`

Convierte **imágenes** de un formato a otro usando FFmpeg.

### Qué hace

- Admite **arrastrar y soltar** o **pegar la ruta**.
- Formatos de salida: **JPEG, PNG, BMP, GIF, TIFF, WEBP**.
- No sobrescribe: si el nombre existe, añade `_1`, `_2`, etc.

### Uso

1. Arrastra una imagen sobre `Format IMG.bat` (o ejecútalo y pega la ruta).
2. Elige el número del formato de salida (1-6).
3. La imagen convertida se guarda en la **misma carpeta** que la original.

---

## `instalar_dependencias.bat`

Prepara y mantiene el equipo para el resto de scripts.

### Qué hace

1. Localiza **Python/pip** (prueba `py -m pip`, `python -m pip` y `pip`).
2. Instala o actualiza **yt-dlp**.
3. Instala o actualiza **spotdl**.
4. Descarga **Deno** (motor JavaScript que yt-dlp necesita para YouTube), reutilizando el de spotdl.
5. Comprueba **ffmpeg** y, si falta, intenta instalarlo con **winget** (o indica cómo hacerlo a mano).
6. Muestra un **resumen de versiones** de todo.

Ejecútalo la primera vez para instalar todo, y cuando quieras **actualizar** las librerías o si una descarga empieza a fallar.

---

## Herramientas usadas

| Herramienta | Uso | Enlace |
|---|---|---|
| yt-dlp | Descargas de YouTube / YouTube Music | https://github.com/yt-dlp/yt-dlp |
| spotDL | Descargas de Spotify (audio) | https://github.com/spotDL/spotify-downloader |
| FFmpeg | Conversión de audio/vídeo/imagen | https://ffmpeg.org/ |
| Deno | Motor JavaScript para yt-dlp | https://deno.com/ |

---

## Solución de problemas

- **"yt-dlp/spotdl no se reconoce" o descargas que fallan** → ejecuta `instalar_dependencias.bat` para instalar/actualizar todo.
- **Descarga solo el audio en un vídeo de YouTube** → falta el motor JavaScript (Deno). Ejecuta `instalar_dependencias.bat`; el downloader lo detecta automáticamente.
- **Spotify no descarga** → necesitas `spotdl` (lo instala `instalar_dependencias.bat`). Recuerda que Spotify solo permite audio (MP3).
- **Conversión falla en `Format VIDEO.bat` / `Format IMG.bat`** → asegúrate de tener `ffmpeg` (lo instala/comprueba `instalar_dependencias.bat`).
- **Una lista grande de YouTube da varios errores 403** → aumenta los segundos de espera entre elementos cuando el script lo pregunte.

---

## Notas

- Los scripts guardan los archivos con el **título original** del contenido; los caracteres no válidos se ajustan automáticamente.
- No se recopila ni envía ningún dato: todo se ejecuta en local en tu equipo.
