# PastePal - macOS Multiple Clipboard Manager

A lightweight macOS menu bar application that provides 9 independent clipboard slots, allowing you to store and paste multiple items using keyboard shortcuts.

## Features

- **9 Independent Clipboard Slots**: Store up to 9 different clipboard contents simultaneously
- **Global Keyboard Shortcuts**: Works system-wide across all applications
- **Menu Bar Interface**: Minimal UI that stays out of your way
- **Visual Feedback**: Notifications confirm save/paste actions
- **Native Integration**: Uses macOS native clipboard functionality

## Keyboard Shortcuts

- **Smart Save/Paste**: `Cmd + Shift + [1-9]`
  - If the slot is empty: Saves the current clipboard content to the slot
  - If the slot has content: Pastes the content from the slot
  
- **Clear Slot**: `Cmd + Shift + Option + [1-9]`
  - Clears the content from the specified slot

## Installation & Setup

1. Navigate to the PastePal directory:
   ```bash
   cd PastePal
   ```

2. Build and run the application:
   ```bash
   ./run.sh
   ```

   Or manually:
   ```bash
   swift build -c release
   ./.build/release/PastePal
   ```

## Permissions Required

The app requires two permissions to function:

1. **Accessibility Permission** (Required)
   - Needed to monitor global keyboard shortcuts
   - Grant via: System Settings → Privacy & Security → Accessibility
   
2. **Notifications Permission** (Optional)
   - For visual feedback when saving/pasting
   - You'll be prompted on first launch

## How It Works

1. Copy any text normally (Cmd+C)
2. Press `Cmd+Shift+1` to save it to slot 1 (slot was empty)
3. Copy something else  
4. Press `Cmd+Shift+2` to save it to slot 2 (slot was empty)
5. Later, press `Cmd+Shift+1` to paste from slot 1 (slot has content)
6. Press `Cmd+Shift+2` to paste from slot 2 (slot has content)
7. Press `Cmd+Shift+Option+1` to clear slot 1

The app runs in your menu bar (look for the clipboard icon) where you can:
- View the contents of each clipboard slot
- Clear all clipboards
- Quit the application

## Technical Details

- Built with Swift and AppKit
- Uses CGEventTap for global keyboard monitoring
- Leverages NSPasteboard for clipboard operations
- Minimal resource usage - runs as menu bar app
- No data persistence - clipboards are cleared on quit

## Troubleshooting

If keyboard shortcuts aren't working:
1. Ensure Accessibility permission is granted
2. Restart the app after granting permissions
3. Check that no other apps are using the same shortcuts

## License

This is a simple utility created for personal use. Feel free to modify and use as needed.