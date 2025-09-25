//
//  AppDelegate.swift
//  pasteman-app
//
//  Created by Trivikram Battalapalli on 9/25/25.
//

import Cocoa
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var globalKeyMonitor: CFMachPort?
    var clipboardManager = ClipboardManager()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Hide dock icon and make this a menu bar only app
        NSApp.setActivationPolicy(.accessory)
        
        setupMenuBar()
        requestAccessibilityPermissions()
        setupGlobalKeyMonitor()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        if let eventTap = globalKeyMonitor {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            // Create a simple diamond template image
            let image = NSImage(size: NSSize(width: 18, height: 18))
            image.lockFocus()
            
            // Draw a diamond shape
            let path = NSBezierPath()
            path.move(to: NSPoint(x: 9, y: 2))   // Top
            path.line(to: NSPoint(x: 16, y: 9))  // Right
            path.line(to: NSPoint(x: 9, y: 16))  // Bottom
            path.line(to: NSPoint(x: 2, y: 9))   // Left
            path.close()
            
            NSColor.black.setFill()
            path.fill()
            
            image.unlockFocus()
            image.isTemplate = true
            
            button.image = image
            button.toolTip = "Pasteman - Clipboard Manager"
        }
        
        createInitialMenu()
    }
    
    private func updateMenu() {
        guard let menu = statusItem?.menu else { return }
        
        // Update clipboard slots 1-10 (items 2-11, after title and separator)
        for i in 1...10 {
            if let menuItem = menu.item(withTag: i) {
                if let content = clipboardManager.getClipboard(at: i - 1) {
                    let displayContent = String(content.prefix(50))
                    let binding = Settings.shared.keyBindings.first { $0.slot == i && $0.action == "save_or_paste" }
                    let keybindText = binding != nil ? " (⌘⇧\(binding!.key.uppercased()))" : ""
                    menuItem.title = "Clipboard \(i): \(displayContent)\(content.count > 50 ? "..." : "")\(keybindText)"
                } else {
                    let binding = Settings.shared.keyBindings.first { $0.slot == i && $0.action == "save_or_paste" }
                    let keybindText = binding != nil ? " (⌘⇧\(binding!.key.uppercased()))" : ""
                    menuItem.title = "Clipboard \(i): Empty\(keybindText)"
                }
            }
        }
    }
    
    private func createInitialMenu() {
        let menu = NSMenu()
        
        // Title
        menu.addItem(NSMenuItem(title: "Pasteman", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Add clipboard slots 1-10
        for i in 1...10 {
            let menuItem = NSMenuItem()
            menuItem.title = "Clipboard \(i): Empty"
            menuItem.tag = i
            menu.addItem(menuItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Clear All", action: #selector(clearAllClipboards), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "How to Use Pasteman", action: #selector(showInfo), keyEquivalent: ""))
        
        // Settings submenu - exactly like original
        let settingsMenuItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        let settingsSubmenu = NSMenu()
        
        for i in 1...10 {
            let slotMenuItem = NSMenuItem(title: "Clipboard \(i) Shortcut", action: nil, keyEquivalent: "")
            let slotSubmenu = NSMenu()
            
            // Add specific keybind options - same as original
            let availableKeys = [
                ("E", "e"), ("J", "j"), ("U", "u"), ("X", "x"), ("Y", "y"),
                ("0", "0"), ("1", "1"), ("2", "2"), ("7", "7"), ("8", "8"), ("9", "9"),
                ("`", "`"), ("[", "["), ("]", "]")
            ]
            
            for (displayKey, actualKey) in availableKeys {
                let keyMenuItem = NSMenuItem(title: "⌘⇧\(displayKey)", action: #selector(setKeybind(_:)), keyEquivalent: "")
                keyMenuItem.tag = i * 1000 + actualKey.hashValue
                keyMenuItem.representedObject = ["slot": i, "key": actualKey]
                slotSubmenu.addItem(keyMenuItem)
            }
            
            slotSubmenu.addItem(NSMenuItem.separator())
            let clearMenuItem = NSMenuItem(title: "Clear Shortcut", action: #selector(clearKeybind(_:)), keyEquivalent: "")
            clearMenuItem.tag = i
            slotSubmenu.addItem(clearMenuItem)
            
            slotMenuItem.submenu = slotSubmenu
            settingsSubmenu.addItem(slotMenuItem)
        }
        
        settingsSubmenu.addItem(NSMenuItem.separator())
        let resetMenuItem = NSMenuItem(title: "Reset All to Defaults", action: #selector(resetAllKeybinds), keyEquivalent: "")
        settingsSubmenu.addItem(resetMenuItem)
        
        settingsMenuItem.submenu = settingsSubmenu
        menu.addItem(settingsMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "😊 Buy Me a Coffee", action: #selector(openBuyMeACoffee), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit Pasteman", action: #selector(quitApplication), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        updateMenuKeyBindings()
    }
    
    private func setupGlobalKeyMonitor() {
        // Check accessibility permissions before creating event tap to prevent system dialog
        guard AXIsProcessTrusted() else {
            return
        }
        
        // Use CGEvent tap like the original for more reliable key capture
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()
                return appDelegate.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return
        }
        
        self.globalKeyMonitor = eventTap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            
            let keyBindings = Settings.shared.keyBindings
            
            for binding in keyBindings {
                if binding.matches(flags: flags, keyCode: keyCode) {
                    guard let slot = binding.slot, slot >= 1 && slot <= 10 else { continue }
                    let slotIndex = slot - 1  // Convert to 0-based index
                    
                    switch binding.action {
                    case "save_or_paste":
                        if clipboardManager.hasContent(at: slotIndex) {
                            clipboardManager.pasteFromClipboard(at: slotIndex)
                        } else {
                            clipboardManager.saveToClipboard(at: slotIndex)
                        }
                    case "clear":
                        clipboardManager.clearSlot(at: slotIndex)
                    default:
                        break
                    }
                    
                    updateMenu()
                    return nil // Consume the event
                }
            }
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private func requestAccessibilityPermissions() {
        // Check accessibility status without showing system prompt
        let accessEnabled = AXIsProcessTrusted()
        
        if !accessEnabled {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "Pasteman needs accessibility permissions to monitor keyboard shortcuts globally. Please:\n\n1. Click 'Open System Preferences' below\n2. Find 'Pasteman' or 'pasteman-app' in the list\n3. Check the box next to it\n4. **RESTART PASTEMAN** (this is required!)\n\n⚠️ **IMPORTANT: You MUST restart the app after granting permissions for them to take effect.**\n\nIf the app doesn't appear in the list, try quitting and relaunching Pasteman first."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                openAccessibilitySettings()
            }
        } else {
            // Permissions are granted, ensure global key monitor is set up
            if globalKeyMonitor == nil {
                setupGlobalKeyMonitor()
            }
        }
    }
    
    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func pasteFromSlot(_ sender: NSMenuItem) {
        clipboardManager.pasteFromClipboard(at: sender.tag)
        updateMenu()
    }
    
    @objc private func clearAllClipboards() {
        clipboardManager.clearAll()
        updateMenu()
    }
    
    @objc private func quitApplication() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc func openBuyMeACoffee() {
        if let url = URL(string: "https://buymeacoffee.com/vikrambattalapalli") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func setKeybind(_ sender: NSMenuItem) {
        guard let info = sender.representedObject as? [String: Any],
              let slot = info["slot"] as? Int,
              let key = info["key"] as? String else { return }
        
        guard slot >= 1 && slot <= 10 else { return }
        
        // Remove any existing bindings for this slot
        var bindings = Settings.shared.keyBindings.filter { $0.slot != slot }
        
        // Add new save/paste binding
        let saveBinding = KeyBinding(
            modifiers: ["cmd", "shift"],
            key: key,
            action: "save_or_paste",
            slot: slot
        )
        bindings.append(saveBinding)
        
        // Add corresponding clear binding (cmd + option + shift + key)
        let clearBinding = KeyBinding(
            modifiers: ["cmd", "option", "shift"],
            key: key,
            action: "clear",
            slot: slot
        )
        bindings.append(clearBinding)
        
        Settings.shared.keyBindings = bindings
        updateMenuKeyBindings()
    }
    
    @objc func clearKeybind(_ sender: NSMenuItem) {
        let slot = sender.tag
        guard slot >= 1 && slot <= 10 else { return }
        
        // Remove binding for this slot
        let bindings = Settings.shared.keyBindings.filter { $0.slot != slot }
        Settings.shared.keyBindings = bindings
        updateMenuKeyBindings()
    }
    
    @objc func resetAllKeybinds() {
        Settings.shared.resetToDefaults()
        updateMenuKeyBindings()
    }
    
    @objc func showInfo() {
        let alert = NSAlert()
        alert.messageText = "How to Use Pasteman"
        alert.informativeText = """
        Pasteman helps you manage multiple clipboard slots with keyboard shortcuts.

        📋 SAVING TO CLIPBOARD SLOTS:
        • Copy text as usual (⌘C)
        • Press ⌘⇧[key] to save to a slot
        • If slot is empty: saves current clipboard
        • If slot has content: pastes from that slot

        🗑️ CLEARING CLIPBOARD SLOTS:
        • Press ⌘⌥⇧[key] to clear a slot
        • This removes all content from that slot

        ⚙️ CHANGING KEYBINDS:
        • Go to Settings in the menu bar
        • Choose a clipboard slot to configure
        • Select from available keys: E,J,U,X,Y / 0,1,2,7,8,9 / `,],[

        📊 DEFAULT KEYBINDS:
        • Slot 1: ⌘⇧1 (save/paste) | ⌘⌥⇧1 (clear)
        • Slot 2: ⌘⇧2 (save/paste) | ⌘⌥⇧2 (clear)
        • Slot 7: ⌘⇧7 (save/paste) | ⌘⌥⇧7 (clear)
        • Slot 8: ⌘⇧8 (save/paste) | ⌘⌥⇧8 (clear)
        • Slot 9: ⌘⇧9 (save/paste) | ⌘⌥⇧9 (clear)

        💡 TIP: You can see slot contents and shortcuts in the menu bar dropdown!
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Got it!")
        alert.runModal()
    }
    
    func updateMenuKeyBindings() {
        guard let menu = statusItem?.menu else { return }
        
        // Find settings submenu and update current selections
        for menuItem in menu.items {
            if menuItem.title == "Settings", let settingsSubmenu = menuItem.submenu {
                for i in 1...10 {
                    if i-1 < settingsSubmenu.items.count,
                       let slotSubmenu = settingsSubmenu.items[i-1].submenu {
                        
                        let currentBinding = Settings.shared.keyBindings.first { $0.slot == i && $0.action == "save_or_paste" }
                        
                        // Update checkmarks
                        for subItem in slotSubmenu.items {
                            subItem.state = .off
                            // Only check keybind items (those with representedObject)
                            if let binding = currentBinding,
                               let info = subItem.representedObject as? [String: Any],
                               let menuKey = info["key"] as? String,
                               menuKey == binding.key {
                                subItem.state = .on
                            }
                        }
                        
                        // Update slot title to show current binding
                        if let binding = currentBinding {
                            settingsSubmenu.items[i-1].title = "Clipboard \(i) Shortcut (⌘⇧\(binding.key.uppercased()))"
                        } else {
                            settingsSubmenu.items[i-1].title = "Clipboard \(i) Shortcut"
                        }
                    }
                }
            }
        }
        
        // Menu items will be refreshed on next menu open
    }
}

