#!/bin/bash

echo "Building Pasteman..."
swift build -c release

echo "Running Pasteman..."
echo "Note: You'll need to grant Accessibility permissions when prompted."
echo ""
echo "Keyboard Shortcuts:"
echo "  Cmd+Shift+1-9: Save to slot (if empty) or Paste from slot (if has content)"
echo "  Cmd+Shift+Option+1-9: Clear the specified slot"
echo ""
echo "The app will run in your menu bar. Look for the clipboard icon."

./.build/release/Pasteman