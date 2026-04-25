#!/usr/bin/env bash
set -euo pipefail

# This script builds a ClipURL.app which allows you to copy text to the clipboard via a custom URL scheme (clip://).

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$HOME/Applications/ClipURL.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"

mkdir -p "$MACOS"

cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>ClipURL</string>
    <key>CFBundleIdentifier</key>
    <string>dev.nicholaswagner.clipurl</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>ClipURL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>Copy to Clipboard</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>clip</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

echo "Compiling ClipURL.swift..."
swiftc "$DOTFILES/src/ClipURL.swift" -o "$MACOS/ClipURL"

echo "Registering with Launch Services..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"

echo "Done — ClipURL.app installed at $APP"
