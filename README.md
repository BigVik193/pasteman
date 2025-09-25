# Pasteman - macOS Multiple Clipboard Manager

A lightweight macOS menu bar application that provides 10 independent clipboard slots with fully configurable keyboard shortcuts, allowing you to store and paste multiple items using your preferred key combinations.

## Features

- **10 Independent Clipboard Slots**: Store up to 10 different clipboard contents simultaneously
- **Configurable Keyboard Shortcuts**: Customize keybinds for each slot through an intuitive settings interface
- **Menu Bar Interface**: Minimal UI that stays out of your way
- **Visual Feedback**: Notifications confirm save/paste actions
- **Native Integration**: Uses macOS native clipboard functionality
- **Persistent Settings**: Your custom keybinds are saved and restored between sessions

## Default Keyboard Shortcuts

By default, 5 slots have pre-configured shortcuts:

- **Smart Save/Paste**: `Cmd + Shift + [1, 2, 7, 8, 9]`
  - If the slot is empty: Saves the current clipboard content to the slot
  - If the slot has content: Pastes the content from the slot

- **Clear Slot**: `Cmd + Option + Shift + [1, 2, 7, 8, 9]`
  - Clears the content from the specified slot (makes it empty)

The remaining slots (3, 4, 5, 6, 10) can be configured with custom shortcuts through the Settings menu.

## Installation

### Homebrew (Recommended)
```bash
brew tap BigVik193/tap
brew install --cask pastepal
```

### Manual Installation
1. Download from [GitHub Releases](https://github.com/BigVik193/pastepal/releases)
2. Extract and move `Pasteman.app` to Applications
3. Launch and grant accessibility permissions

**Note:** If you see "Pasteman is damaged", run:
```bash
sudo xattr -rd com.apple.quarantine /Applications/Pasteman.app
```

### Development Setup
1. Navigate to the Pasteman directory:
   ```bash
   cd Pasteman
   ```

2. Build and run the application:
   ```bash
   ./run.sh
   ```

   Or manually:
   ```bash
   swift build -c release
   ./.build/release/Pasteman
   ```

## Permissions Required

The app requires two permissions to function:

1. **Accessibility Permission** (Required)
   - Needed to monitor global keyboard shortcuts
   - Grant via: System Settings → Privacy & Security → Accessibility
   
2. **Notifications Permission** (Optional)
   - For visual feedback when saving/pasting
   - You'll be prompted on first launch

## Configuring Keyboard Shortcuts

1. Click the clipboard icon in your menu bar
2. Navigate to **"Settings"** → **"Clipboard [X] Shortcut"** 
3. Choose from available key combinations: ⌘⇧E, ⌘⇧J, ⌘⇧U, ⌘⇧X, ⌘⇧Y, ⌘⇧0, ⌘⇧1, ⌘⇧2, ⌘⇧7, ⌘⇧8, ⌘⇧9, ⌘⇧`, ⌘⇧[, ⌘⇧]
4. Click your desired shortcut to assign it to that slot
5. Use **"Clear Shortcut"** to remove a keybind
6. Use **"Reset All to Defaults"** to restore original settings

### Important Notes
- When you set a save/paste shortcut, a corresponding clear shortcut is automatically created
- For example, setting ⌘⇧E for save/paste also creates ⌘⌥⇧E for clearing
- Available keys: Letters (E, J, U, X, Y), Numbers (0, 1, 2, 7, 8, 9), Symbols (`, [, ])

### Getting Help
- Click **"Settings"** → **"How to Use Pasteman"** for a comprehensive in-app guide

## How It Works

### Basic Workflow
1. Copy any text normally (Cmd+C)
2. Press `Cmd+Shift+1` to save it to slot 1 (slot was empty)
3. Copy something else  
4. Press `Cmd+Shift+2` to save it to slot 2 (slot was empty)
5. Later, press `Cmd+Shift+1` to paste from slot 1 (slot has content)
6. Press `Cmd+Shift+2` to paste from slot 2 (slot has content)

### Clearing Slots
- Press `Cmd+Option+Shift+1` to clear slot 1
- Press `Cmd+Option+Shift+2` to clear slot 2
- Or use the menu bar "Clear All" option to clear everything

### Menu Bar Interface
The app runs in your menu bar (look for the clipboard icon) where you can:
- View the contents of each clipboard slot (1-10)
- See current keyboard shortcuts for each slot
- Access Settings to configure custom shortcuts
- Get help with "How to Use Pasteman"
- Clear all clipboards
- Quit the application

## Technical Details

- Built with Swift and AppKit
- Uses CGEventTap for global keyboard monitoring
- Leverages NSPasteboard for clipboard operations
- Settings stored in UserDefaults for persistence
- Configurable keybinds support any modifier + key combination
- Minimal resource usage - runs as menu bar app
- No clipboard data persistence - clipboards are cleared on quit

## Troubleshooting

If keyboard shortcuts aren't working:
1. Ensure Accessibility permission is granted
2. Restart the app after granting permissions
3. Check that no other apps are using the same shortcuts
4. Try reconfiguring the problematic shortcuts through Settings

If the Settings window buttons don't respond:
- Make sure you're running the latest build
- Try closing and reopening the Settings window

## License

This is a simple utility created for personal use. Feel free to modify and use as needed.