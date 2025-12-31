@echo off
echo 🚀 Building CMMS Mobile App...
echo.

echo 📦 Getting Flutter dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Failed to get dependencies
    pause
    exit /b 1
)

echo.
echo 🔍 Checking Flutter setup...
flutter doctor
if %errorlevel% neq 0 (
    echo ⚠️ Flutter doctor found issues, but continuing...
)

echo.
echo 🧹 Cleaning previous builds...
flutter clean

echo.
echo 📱 Building debug APK...
flutter build apk --debug
if %errorlevel% neq 0 (
    echo ❌ Failed to build debug APK
    pause
    exit /b 1
)

echo.
echo 🎯 Building release APK...
flutter build apk --release
if %errorlevel% neq 0 (
    echo ❌ Failed to build release APK
    pause
    exit /b 1
)

echo.
echo 📦 Building app bundle for Play Store...
flutter build appbundle --release
if %errorlevel% neq 0 (
    echo ❌ Failed to build app bundle
    pause
    exit /b 1
)

echo.
echo ✅ Build completed successfully!
echo.
echo 📁 Build outputs:
echo    Debug APK: build\app\outputs\flutter-apk\app-debug.apk
echo    Release APK: build\app\outputs\flutter-apk\app-release.apk
echo    App Bundle: build\app\outputs\bundle\release\app-release.aab
echo.
echo 🎉 Your CMMS mobile app is ready for deployment!
echo.
pause





















