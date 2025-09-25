#!/bin/bash

# DMG Creation Script for Pasteman
# Creates a DMG with drag-to-Applications functionality

set -e

APP_NAME="Pasteman"
VERSION="1.0.2"
DMG_NAME="${APP_NAME}-${VERSION}"
APP_PATH="build/${APP_NAME}.app"
DMG_DIR="dmg_temp"
FINAL_DMG="release/${DMG_NAME}.dmg"

echo "🔨 Creating DMG for ${APP_NAME} v${VERSION}..."

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: ${APP_PATH} not found. Please build the app first."
    exit 1
fi

# Clean up any existing temp directory
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
mkdir -p "release"

# Copy the app to temp directory
echo "📦 Copying app bundle..."
cp -R "$APP_PATH" "$DMG_DIR/"

# Create Applications symlink for drag-and-drop
echo "🔗 Creating Applications symlink..."
ln -s /Applications "$DMG_DIR/Applications"

# Create a temporary DMG
echo "💿 Creating temporary DMG..."
TEMP_DMG="temp_${DMG_NAME}.dmg"
hdiutil create -srcfolder "$DMG_DIR" -volname "$APP_NAME" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size 100m "$TEMP_DMG"

# Mount the temporary DMG
echo "📁 Mounting DMG for customization..."
MOUNT_DIR="/Volumes/$APP_NAME"
hdiutil attach "$TEMP_DMG" -readwrite -mount required

# Wait for mount
sleep 2

# Set DMG window properties using AppleScript
echo "🎨 Customizing DMG appearance..."
osascript <<EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 400}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 72
        set position of item "$APP_NAME.app" of container window to {150, 200}
        set position of item "Applications" of container window to {350, 200}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Simple setup without custom background
echo "📝 Setting up DMG layout..."

# Sync and unmount
echo "💾 Finalizing DMG..."
sync
hdiutil detach "$MOUNT_DIR"

# Convert to final compressed DMG
echo "🗜️  Compressing DMG..."
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG"

# Clean up
rm -f "$TEMP_DMG"
rm -rf "$DMG_DIR"

echo "✅ DMG created successfully: $FINAL_DMG"
echo "📂 Size: $(du -h "$FINAL_DMG" | cut -f1)"
echo ""
echo "🎉 Your DMG is ready! Users can:"
echo "   1. Download and double-click the DMG"
echo "   2. Drag $APP_NAME.app to the Applications folder"
echo "   3. Launch from Applications"