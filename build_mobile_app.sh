#!/bin/bash

echo "🚀 Building CMMS Mobile App..."
echo

echo "📦 Getting Flutter dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ Failed to get dependencies"
    exit 1
fi

echo
echo "🔍 Checking Flutter setup..."
flutter doctor

echo
echo "🧹 Cleaning previous builds..."
flutter clean

echo
echo "📱 Building debug APK..."
flutter build apk --debug
if [ $? -ne 0 ]; then
    echo "❌ Failed to build debug APK"
    exit 1
fi

echo
echo "🎯 Building release APK..."
flutter build apk --release
if [ $? -ne 0 ]; then
    echo "❌ Failed to build release APK"
    exit 1
fi

echo
echo "📦 Building app bundle for Play Store..."
flutter build appbundle --release
if [ $? -ne 0 ]; then
    echo "❌ Failed to build app bundle"
    exit 1
fi

echo
echo "✅ Build completed successfully!"
echo
echo "📁 Build outputs:"
echo "   Debug APK: build/app/outputs/flutter-apk/app-debug.apk"
echo "   Release APK: build/app/outputs/flutter-apk/app-release.apk"
echo "   App Bundle: build/app/outputs/bundle/release/app-release.aab"
echo
echo "🎉 Your CMMS mobile app is ready for deployment!"





















