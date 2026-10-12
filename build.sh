#!/bin/sh
# Builds Cadence.app next to this script. No Xcode project needed, just the Command Line Tools.
#   ./build.sh              -> version 0.0.0-dev
#   VERSION=1.2.3 ./build.sh
set -e
cd "$(dirname "$0")"
VERSION=${VERSION:-0.0.0-dev}
APP=Cadence.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -o "$APP/Contents/MacOS/Cadence" main.swift
cp assets/AppIcon.icns "$APP/Contents/Resources/"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Cadence</string>
  <key>CFBundleDisplayName</key><string>Cadence</string>
  <key>CFBundleExecutable</key><string>Cadence</string>
  <key>CFBundleIdentifier</key><string>io.github.nicholastn1.cadence</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSMicrophoneUsageDescription</key><string>Listens while you read so the script scrolls at your pace.</string>
  <key>NSSpeechRecognitionUsageDescription</key><string>Recognizes your words on-device to find your place in the script.</string>
</dict></plist>
PLIST
codesign --force -s - "$APP"
echo "Built $APP $VERSION"
