#!/bin/bash

# Icon Generation Script for PastePal
# Generates macOS icon set from a 1024x1024 PNG

set -e

SOURCE_ICON="PastePal/Resources/icon.png"
ICONSET_DIR="PastePal/Resources/AppIcon.iconset"
OUTPUT_ICNS="PastePal/Resources/AppIcon.icns"

echo "🎨 Generating macOS icon set from ${SOURCE_ICON}..."

# Check if source icon exists
if [ ! -f "$SOURCE_ICON" ]; then
    echo "❌ Error: Source icon not found at $SOURCE_ICON"
    exit 1
fi

# Check if sips is available (built into macOS)
if ! command -v sips &> /dev/null; then
    echo "❌ Error: sips command not found. This script requires macOS."
    exit 1
fi

# Clean up existing iconset
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# Define the required icon sizes for macOS
declare -a sizes=(
    "16,icon_16x16.png"
    "32,icon_16x16@2x.png"
    "32,icon_32x32.png"
    "64,icon_32x32@2x.png"
    "128,icon_128x128.png"
    "256,icon_128x128@2x.png"
    "256,icon_256x256.png"
    "512,icon_256x256@2x.png"
    "512,icon_512x512.png"
    "1024,icon_512x512@2x.png"
)

echo "📐 Generating icon sizes..."

# Generate each size using sips
for size_info in "${sizes[@]}"; do
    IFS=',' read -r size filename <<< "$size_info"
    echo "  Creating ${filename} (${size}x${size})"
    sips -z "$size" "$size" "$SOURCE_ICON" --out "$ICONSET_DIR/$filename" > /dev/null 2>&1
done

# Convert iconset to icns using iconutil (built into macOS)
echo "🔄 Converting to ICNS format..."
iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"

# Clean up iconset directory
rm -rf "$ICONSET_DIR"

echo "✅ Icon generation complete!"
echo "📁 Generated: $OUTPUT_ICNS"
echo "📏 Size: $(du -h "$OUTPUT_ICNS" | cut -f1)"

# Verify the generated icon
if [ -f "$OUTPUT_ICNS" ]; then
    echo "🔍 Icon verification:"
    file "$OUTPUT_ICNS"
else
    echo "❌ Error: Failed to generate $OUTPUT_ICNS"
    exit 1
fi