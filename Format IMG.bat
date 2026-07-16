@echo off
setlocal enabledelayedexpansion

REM Si se pasa un argumento (drag & drop), usarlo directamente
if "%~1"=="" (
    set /p file_path="Enter the full path of the image file: "
) else (
    set "file_path=%~1"
)

REM Quitar comillas (por si acaso)
set "file_path=%file_path:"=%"

REM Comprobar si el archivo existe
if not exist "%file_path%" (
    echo The file does not exist.
    pause
    exit /b
)

REM Extraer nombre, carpeta y extension
for %%F in ("%file_path%") do set "file_name=%%~nF"
for %%F in ("%file_path%") do set "file_dir=%%~dpF"
for %%F in ("%file_path%") do set "file_ext=%%~xF"

REM Mostrar opciones
echo Select the format for conversion:
echo 1. JPEG
echo 2. PNG
echo 3. BMP
echo 4. GIF
echo 5. TIFF
echo 6. WEBP
set /p format_choice="Enter your choice (1-6): "

REM Determinar formato
if "%format_choice%"=="1" set format=jpg
if "%format_choice%"=="2" set format=png
if "%format_choice%"=="3" set format=bmp
if "%format_choice%"=="4" set format=gif
if "%format_choice%"=="5" set format=tiff
if "%format_choice%"=="6" set format=webp

if not defined format (
    echo Invalid choice! Please select a number between 1 and 6.
    pause
    exit /b
)

REM Generar nombre de salida (evita sobreescribir)
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

REM Ejecutar FFmpeg
ffmpeg -i "%file_path%" "%output_file%"
echo Conversion complete! File saved as "%output_file%"

pause
