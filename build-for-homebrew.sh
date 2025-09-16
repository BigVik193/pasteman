#!/bin/bash

# Simple build script for Homebrew distribution
# No code signing needed - much simpler than DMG approach!

set -e

APP_NAME="PastePal"
VERSION="1.0.0"
BUILD_DIR="$(pwd)/build"
RELEASE_DIR="$(pwd)/release"

echo "🍺 Building ${APP_NAME} for Homebrew distribution..."

# Clean previous builds
rm -rf "${BUILD_DIR}" "${RELEASE_DIR}"
mkdir -p "${BUILD_DIR}" "${RELEASE_DIR}"

# Build the Swift package (universal binary for Intel + Apple Silicon)
echo "📦 Building Swift package..."
cd PastePal
swift build -c release --arch arm64 --arch x86_64

# Create the app bundle
echo "🏗️  Creating app bundle..."
cd ..
mkdir -p "${BUILD_DIR}/${APP_NAME}.app/Contents/MacOS"
mkdir -p "${BUILD_DIR}/${APP_NAME}.app/Contents/Resources"

# Copy the executable
cp "PastePal/.build/release/${APP_NAME}" "${BUILD_DIR}/${APP_NAME}.app/Contents/MacOS/${APP_NAME}"

# Create Info.plist
cat > "${BUILD_DIR}/${APP_NAME}.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.pastepal.app</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © $(date +%Y) PastePal. All rights reserved.</string>
    <key>NSPrivacyAccessibilityUsageDescription</key>
    <string>PastePal needs accessibility access to monitor global keyboard shortcuts and simulate paste operations.</string>
</dict>
</plist>
EOF

# Create a simple icon (replace with your actual icon)
# For now, we'll use a system icon - you should replace this with your custom .icns file
echo "🎨 Adding app icon..."
# You can create an .icns file from a PNG using: iconutil -c icns icon.iconset
# For now, the app will use a default icon

# Create the release ZIP
echo "📦 Creating release ZIP..."
cd "${BUILD_DIR}"
zip -r "${RELEASE_DIR}/${APP_NAME}-${VERSION}.zip" "${APP_NAME}.app"

echo "✅ Build complete!"
echo ""
echo "📁 Files created:"
echo "   App Bundle: ${BUILD_DIR}/${APP_NAME}.app"
echo "   Release ZIP: ${RELEASE_DIR}/${APP_NAME}-${VERSION}.zip"
echo ""
echo "🚀 Next steps for Homebrew distribution:"
echo "1. Upload ${APP_NAME}-${VERSION}.zip to GitHub Releases"
echo "2. Get the download URL and SHA256 hash"
echo "3. Update pastepal.rb with the real URL and hash"
echo "4. Submit to homebrew-cask or create your own tap"
echo ""
echo "💡 To calculate SHA256 hash:"
echo "   shasum -a 256 ${RELEASE_DIR}/${APP_NAME}-${VERSION}.zip"