#!/bin/bash
# Builds Brasa (only the Command Line Tools are needed) and installs it to ~/Applications/Brasa.app
set -e
cd "$(dirname "$0")"
APP=build/Brasa.app
rm -rf build && mkdir -p $APP/Contents/MacOS
swiftc -O -swift-version 5 -parse-as-library -target arm64-apple-macos14 Brasa.swift Localization.swift -o $APP/Contents/MacOS/Brasa
mkdir -p $APP/Contents/Resources && cp brand/kit/app/AppIcon.icns $APP/Contents/Resources/AppIcon.icns
cat > $APP/Contents/Info.plist <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>br.com.renato.brasa</string>
  <key>CFBundleName</key><string>Brasa</string>
  <key>CFBundleDisplayName</key><string>Brasa</string>
  <key>CFBundleExecutable</key><string>Brasa</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PL
codesign --force --sign - $APP
pkill -x Brasa 2>/dev/null || true   # quit the running app before replacing it
mkdir -p ~/Applications && rm -rf ~/Applications/Brasa.app && cp -R $APP ~/Applications/
echo "installed: ~/Applications/Brasa.app"
