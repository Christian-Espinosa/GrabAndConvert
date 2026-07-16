# Media download & conversion scripts (Windows)

A collection of `.bat` scripts for **Windows** to download music/video and convert media files quickly and easily, with no GUI apps required.

Everything works through interactive menus in the console. The scripts are built on three well-known open-source tools: [yt-dlp](https://github.com/yt-dlp/yt-dlp), [spotDL](https://github.com/spotDL/spotify-downloader) and [FFmpeg](https://ffmpeg.org/).

> Responsible use: only download content you have the rights to, or that is allowed to be downloaded. Respect each platform's terms of service and your local laws.

---

## What's in this repository

| Script | What it does |
|---|---|
| `youtube downloader.bat` | Downloads songs, videos, playlists and albums from **YouTube**, **YouTube Music** and **Spotify** as MP3 or MP4. |
| `Format VIDEO.bat` | Converts **audio or video** files between formats (mp3, mp4, wav, mkv, flac, etc.). |
| `Format IMG.bat` | Converts **images** between formats (jpg, png, webp, gif, etc.). |
| `install_dependencies.bat` | Checks, **installs and updates** all the libraries the scripts need. |

---

## Requirements

- **Windows** with `cmd` (the scripts are `.bat` files).
- **Python 3** (includes `pip`) — needed to install `yt-dlp` and `spotdl`.
  - Get it from [python.org](https://www.python.org/downloads/) and tick **"Add Python to PATH"** during installation.
- The remaining dependencies (`yt-dlp`, `spotdl`, `ffmpeg`, `Deno`) are installed automatically by `install_dependencies.bat`.

### Quick setup

1. Install Python (see above).
2. Run **`install_dependencies.bat`** (double-click).

That gets your machine ready: it installs yt-dlp, spotdl, ffmpeg (via winget when available) and Deno, and prints a version summary.

---

## `youtube downloader.bat`

Downloads content from **YouTube**, **YouTube Music** and **Spotify**.

### What it does

- **Auto-detects the platform** from the URL:
  - **YouTube / YouTube Music** → uses `yt-dlp` (MP3 or MP4).
  - **Spotify** → uses `spotdl`. Spotify only allows **audio (MP3)**; video is not available, so it is forced to MP3.
- Accepts a **single song/video** or a **playlist/album**.
  - If it detects a playlist, it **asks** whether you want the whole thing (in case it is a single video inside a list).
  - **Only for playlists**, it applies a **wait of X seconds** between items (configurable, default 5) to avoid platform rate limits. A single song is downloaded with no wait.
- Lets you choose **MP3** (audio only) or **MP4** (video).
  - For **MP4**, you can pick the **maximum quality**: 2160p (4K), 1440p (2K), **1080p (default)**, 720p or 480p. It downloads that resolution or the closest one below it.
- **Cleans the URL** automatically: strips any text you paste in front (e.g. "Listen to this playlist: ...") and supports URLs with `&` (parameters like `?si=...&utm_source=...`).
- It does not check for updates on startup (it's fast). If something fails, update with `install_dependencies.bat`.

### Resilience

- MP4 videos prefer **H.264 + AAC** (maximum compatibility with players and DJ software), falling back to the best available.
- Uses **Deno** (auto-detected) to solve the JavaScript challenge YouTube requires; without it, sometimes only the audio would be available.
- If a format returns a 403 error, it **automatically retries** with an alternative stream (HLS).
- For playlists it uses `--ignore-errors`: if an item is unavailable, it is skipped and the rest continue.

### Usage

1. Run `youtube downloader.bat`.
2. Paste the **URL** (song, video, playlist or album).
3. If it's a playlist, confirm whether you want to download the whole thing.
4. Choose the **format** (MP3/MP4) and, for MP4, the **quality**.
5. Enter the destination **folder** (Enter = current folder).
6. For playlists, enter the **wait seconds** between items.

Valid URL examples:

- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- `https://music.youtube.com/watch?v=VIDEO_ID&si=...`
- `https://music.youtube.com/playlist?list=PLAYLIST_ID`
- `https://open.spotify.com/track/...`
- `https://open.spotify.com/playlist/...` / `https://open.spotify.com/album/...`

---

## `Format VIDEO.bat`

Converts **audio or video** files from one format to another using FFmpeg.

### What it does

- Accepts the file path in two ways:
  - **Drag & drop** the file onto the `.bat`, or
  - **paste the path** when prompted.
- Available output formats:
  - Audio: **MP3, WAV, AAC, FLAC, OGG**
  - Video: **MP4, AVI, MKV, MOV, WMV**
- If a file with the same name already exists, it **won't overwrite** it: it creates `name_1`, `name_2`, etc.

### Usage

1. Drag a file onto `Format VIDEO.bat` (or run it and paste the path).
2. Choose the output format number (1-10).
3. The converted file is saved in the **same folder** as the original.

---

## `Format IMG.bat`

Converts **images** from one format to another using FFmpeg.

### What it does

- Accepts **drag & drop** or a **pasted path**.
- Output formats: **JPEG, PNG, BMP, GIF, TIFF, WEBP**.
- Won't overwrite: if the name exists, it appends `_1`, `_2`, etc.

### Usage

1. Drag an image onto `Format IMG.bat` (or run it and paste the path).
2. Choose the output format number (1-6).
3. The converted image is saved in the **same folder** as the original.

---

## `install_dependencies.bat`

Prepares and maintains your machine for the other scripts.

### What it does

1. Locates **Python/pip** (tries `py -m pip`, `python -m pip` and `pip`).
2. Installs or updates **yt-dlp**.
3. Installs or updates **spotdl**.
4. Downloads **Deno** (the JavaScript runtime yt-dlp needs for YouTube), reusing spotdl's copy.
5. Checks **ffmpeg** and, if missing, tries to install it with **winget** (or explains how to do it manually).
6. Prints a **version summary** of everything.

Run it the first time to install everything, and whenever you want to **update** the libraries or if a download starts failing.

---

## Tools used

| Tool | Used for | Link |
|---|---|---|
| yt-dlp | YouTube / YouTube Music downloads | https://github.com/yt-dlp/yt-dlp |
| spotDL | Spotify downloads (audio) | https://github.com/spotDL/spotify-downloader |
| FFmpeg | Audio/video/image conversion | https://ffmpeg.org/ |
| Deno | JavaScript runtime for yt-dlp | https://deno.com/ |

---

## Troubleshooting

- **"yt-dlp/spotdl not recognized" or downloads failing** → run `install_dependencies.bat` to install/update everything.
- **A YouTube video only downloads the audio** → the JavaScript runtime (Deno) is missing. Run `install_dependencies.bat`; the downloader detects it automatically.
- **Spotify won't download** → you need `spotdl` (installed by `install_dependencies.bat`). Remember Spotify only allows audio (MP3).
- **Conversion fails in `Format VIDEO.bat` / `Format IMG.bat`** → make sure `ffmpeg` is installed (checked/installed by `install_dependencies.bat`).
- **A large YouTube playlist throws several 403 errors** → increase the wait seconds between items when the script asks.

---

## Notes

- The scripts save files using the **original title** of the content; invalid characters are adjusted automatically.
- No data is collected or sent: everything runs locally on your machine.
