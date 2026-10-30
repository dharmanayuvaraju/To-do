@echo off
echo ========================================================
echo        🌸 Do It Now - 1-Click APK Builder 🌸
echo ========================================================
echo.

:: Check if flutter is in PATH
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Flutter is not found in your system PATH.
    echo.
    echo To install Flutter automatically, run:
    echo     winget install Google.Flutter
    echo.
    echo Or download Flutter SDK from: https://docs.flutter.dev/get-started/install/windows
    pause
    exit /b 1
)

echo [1/3] Getting Flutter packages...
call flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] flutter pub get failed.
    pause
    exit /b 1
)

echo.
echo [2/3] Building Release APK for Android...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo [ERROR] Flutter build failed.
    pause
    exit /b 1
)

echo.
echo [3/3] Copying APK directly to this folder...
copy /y "build\app\outputs\flutter-apk\app-release.apk" "MaaMadhuram.apk"

echo.
echo ========================================================
echo   ✅ SUCCESS! Your APK is ready in this local folder:
echo       %~dp0MaaMadhuram.apk
echo ========================================================
echo.
echo Send 'MaaMadhuram.apk' to her phone via WhatsApp or Drive!
echo.
pause

