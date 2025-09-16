import Cocoa
import Carbon

struct KeyBinding: Codable {
    let modifiers: [String]
    let key: String
    let action: String
    let slot: Int?
    
    func matches(flags: CGEventFlags, keyCode: Int64) -> Bool {
        let expectedFlags = modifiers.reduce(CGEventFlags()) { result, modifier in
            switch modifier {
            case "cmd": return result.union(.maskCommand)
            case "shift": return result.union(.maskShift)
            case "option": return result.union(.maskAlternate)
            case "ctrl": return result.union(.maskControl)
            default: return result
            }
        }
        
        let keyMatches: Bool
        if let keyAsNumber = Int(key) {
            let mappedNumber = keyCodeToNumber(keyCode)
            keyMatches = mappedNumber == keyAsNumber
        } else {
            keyMatches = keyCodeToCharacter(keyCode) == key
        }
        let flagsMatch = flags.intersection([.maskCommand, .maskShift, .maskAlternate, .maskControl]) == expectedFlags
        
        return keyMatches && flagsMatch
    }
    
    private func keyCodeToNumber(_ keyCode: Int64) -> Int? {
        switch keyCode {
        case 29: return 0  // 0 key for slot 10
        case 18: return 1
        case 19: return 2
        case 20: return 3
        case 21: return 4
        case 23: return 5
        case 22: return 6
        case 26: return 7
        case 28: return 8
        case 25: return 9
        default: return nil
        }
    }
    
    private func keyCodeToCharacter(_ keyCode: Int64) -> String? {
        switch keyCode {
        case 0: return "a"
        case 11: return "b"
        case 8: return "c"
        case 2: return "d"
        case 14: return "e"
        case 3: return "f"
        case 5: return "g"
        case 4: return "h"
        case 34: return "i"
        case 38: return "j"
        case 40: return "k"
        case 37: return "l"
        case 46: return "m"
        case 45: return "n"
        case 31: return "o"
        case 35: return "p"
        case 12: return "q"
        case 15: return "r"
        case 1: return "s"
        case 17: return "t"
        case 32: return "u"
        case 9: return "v"
        case 13: return "w"
        case 7: return "x"
        case 16: return "y"
        case 6: return "z"
        case 50: return "`"
        case 33: return "["
        case 30: return "]"
        default: return nil
        }
    }
}

class Settings {
    static let shared = Settings()
    private let userDefaults = UserDefaults.standard
    private let keybindingsKey = "keybindings"
    
    private init() {}
    
    var keyBindings: [KeyBinding] {
        get {
            if let data = userDefaults.data(forKey: keybindingsKey),
               let bindings = try? JSONDecoder().decode([KeyBinding].self, from: data) {
                return ensureClearBindingsExist(bindings)
            }
            return defaultKeyBindings()
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: keybindingsKey)
            }
        }
    }
    
    private func ensureClearBindingsExist(_ bindings: [KeyBinding]) -> [KeyBinding] {
        var updatedBindings = bindings
        
        // Find all save_or_paste bindings that don't have corresponding clear bindings
        let saveBindings = bindings.filter { $0.action == "save_or_paste" }
        
        for saveBinding in saveBindings {
            guard let slot = saveBinding.slot else { continue }
            
            // Check if clear binding already exists for this slot and key
            let clearExists = bindings.contains { 
                $0.action == "clear" && 
                $0.slot == slot && 
                $0.key == saveBinding.key &&
                $0.modifiers.contains("cmd") &&
                $0.modifiers.contains("option") &&
                $0.modifiers.contains("shift")
            }
            
            if !clearExists {
                // Create corresponding clear binding
                let clearBinding = KeyBinding(
                    modifiers: ["cmd", "option", "shift"],
                    key: saveBinding.key,
                    action: "clear",
                    slot: slot
                )
                updatedBindings.append(clearBinding)
            }
        }
        
        return updatedBindings
    }
    
    private func defaultKeyBindings() -> [KeyBinding] {
        var bindings: [KeyBinding] = []
        
        let defaultBindings = [
            (1, "1"), (2, "2"), (7, "7"), (8, "8"), (9, "9")
        ]
        
        // Add save_or_paste bindings (cmd + shift + key)
        for (slot, key) in defaultBindings {
            bindings.append(KeyBinding(
                modifiers: ["cmd", "shift"],
                key: key,
                action: "save_or_paste",
                slot: slot
            ))
            
            // Automatically add corresponding clear binding (cmd + option + shift + key)
            bindings.append(KeyBinding(
                modifiers: ["cmd", "option", "shift"],
                key: key,
                action: "clear",
                slot: slot
            ))
        }
        
        return bindings
    }
    
    func resetToDefaults() {
        keyBindings = defaultKeyBindings()
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var clipboardManager: ClipboardManager!
    var eventMonitor: EventMonitor!
    
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        
        clipboardManager = ClipboardManager()
        eventMonitor = EventMonitor(clipboardManager: clipboardManager)
        
        requestAccessibilityPermissions()
        
        // Initialize menu with current keybindings
        updateMenuKeyBindings()
        
        eventMonitor.start()
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "PastePal")
            button.image?.isTemplate = true
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "PastePal", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        for i in 1...10 {
            let item = NSMenuItem(title: "Clipboard \(i): Empty", action: nil, keyEquivalent: "")
            item.tag = i
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Clear All", action: #selector(clearAll), keyEquivalent: ""))
        
        // Add Settings submenu
        let settingsMenuItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        let settingsSubmenu = NSMenu()
        
        for i in 1...10 {
            let slotMenuItem = NSMenuItem(title: "Clipboard \(i) Shortcut", action: nil, keyEquivalent: "")
            let slotSubmenu = NSMenu()
            
            // Add specific keybind options
            let availableKeys = [
                ("E", "e"), ("J", "j"), ("U", "u"), ("X", "x"), ("Y", "y"),
                ("0", "0"), ("1", "1"), ("2", "2"), ("7", "7"), ("8", "8"), ("9", "9"),
                ("`", "`"), ("[", "["), ("]", "]")
            ]
            
            for (displayKey, actualKey) in availableKeys {
                let keyMenuItem = NSMenuItem(title: "⌘⇧\(displayKey)", action: #selector(setKeybind(_:)), keyEquivalent: "")
                keyMenuItem.tag = i * 1000 + actualKey.hashValue // Use hashValue for unique identification
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
        let infoMenuItem = NSMenuItem(title: "How to Use PastePal", action: #selector(showInfo), keyEquivalent: "")
        settingsSubmenu.addItem(infoMenuItem)
        
        let resetMenuItem = NSMenuItem(title: "Reset All to Defaults", action: #selector(resetAllKeybinds), keyEquivalent: "")
        settingsSubmenu.addItem(resetMenuItem)
        
        settingsMenuItem.submenu = settingsSubmenu
        menu.addItem(settingsMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func clearAll() {
        clipboardManager.clearAll()
        updateMenu()
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
        alert.messageText = "How to Use PastePal"
        alert.informativeText = """
        PastePal helps you manage multiple clipboard slots with keyboard shortcuts.

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
        • Clear keybinds remove both save/paste and clear shortcuts

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
    
    func updateMenu() {
        guard let menu = statusItem.menu else { return }
        
        for i in 1...10 {
            if let item = menu.item(withTag: i) {
                let content = clipboardManager.getClipboard(at: i - 1)
                let binding = Settings.shared.keyBindings.first { $0.slot == i }
                let keybindText = binding != nil ? " (⌘⇧\(binding!.key.uppercased()))" : ""
                
                if let content = content {
                    let preview = String(content.prefix(50))
                    item.title = "Clipboard \(i): \(preview)\(content.count > 50 ? "..." : "")\(keybindText)"
                } else {
                    item.title = "Clipboard \(i): Empty\(keybindText)"
                }
            }
        }
    }
    
    func updateMenuKeyBindings() {
        guard let menu = statusItem.menu else { return }
        
        // Find settings submenu and update current selections
        for menuItem in menu.items {
            if menuItem.title == "Settings", let settingsSubmenu = menuItem.submenu {
                for i in 1...10 {
                    if i-1 < settingsSubmenu.items.count,
                       let slotSubmenu = settingsSubmenu.items[i-1].submenu {
                        
                        let currentBinding = Settings.shared.keyBindings.first { $0.slot == i }
                        
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
        
        updateMenu() // Also update the main menu items
    }
    
    func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "PastePal needs accessibility permissions to monitor keyboard shortcuts globally. Please grant permission in System Preferences > Security & Privacy > Privacy > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

class ClipboardManager {
    private var clipboards: [String?] = Array(repeating: nil, count: 10)
    private let pasteboard = NSPasteboard.general
    
    func saveToClipboard(at index: Int) {
        guard index >= 0 && index < 10 else { return }
        
        if let string = pasteboard.string(forType: .string) {
            clipboards[index] = string
            
            NSSound.beep()
            
            showNotification(title: "Clipboard \(index + 1) Saved", 
                           body: String(string.prefix(100)))
        }
    }
    
    func pasteFromClipboard(at index: Int) {
        guard index >= 0 && index < 10 else { return }
        guard let content = clipboards[index] else {
            NSSound.beep()
            return
        }
        
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        
        simulatePaste()
        
        showNotification(title: "Pasted from Clipboard \(index + 1)",
                       body: String(content.prefix(100)))
    }
    
    func getClipboard(at index: Int) -> String? {
        guard index >= 0 && index < 10 else { return nil }
        return clipboards[index]
    }
    
    func clearAll() {
        clipboards = Array(repeating: nil, count: 10)
        showNotification(title: "All Clipboards Cleared", body: "")
    }
    
    func clearSlot(at index: Int) {
        guard index >= 0 && index < 10 else { return }
        
        if clipboards[index] != nil {
            clipboards[index] = nil
            showNotification(title: "Clipboard \(index + 1) Cleared", body: "")
        } else {
            NSSound.beep()
            showNotification(title: "Clipboard \(index + 1) Already Empty", body: "")
        }
    }
    
    func hasContent(at index: Int) -> Bool {
        guard index >= 0 && index < 10 else { return false }
        return clipboards[index] != nil
    }
    
    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        let pasteKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        pasteKeyDown?.flags = .maskCommand
        
        let pasteKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        pasteKeyUp?.flags = .maskCommand
        
        pasteKeyDown?.post(tap: .cghidEventTap)
        pasteKeyUp?.post(tap: .cghidEventTap)
    }
    
    private func showNotification(title: String, body: String) {
        print("\(title): \(body)")
    }
}

class EventMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let clipboardManager: ClipboardManager
    private weak var appDelegate: AppDelegate?
    
    init(clipboardManager: ClipboardManager) {
        self.clipboardManager = clipboardManager
        
        if let app = NSApp.delegate as? AppDelegate {
            self.appDelegate = app
        }
    }
    
    func start() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let monitor = Unmanaged<EventMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            
            let keyBindings = Settings.shared.keyBindings
            
            for binding in keyBindings {
                if binding.matches(flags: flags, keyCode: keyCode) {
                    guard let slot = binding.slot, slot >= 0 && slot <= 10 else { continue }
                    let slotIndex = slot == 0 ? 9 : slot - 1  // Map slot 0 to index 9 (slot 10)
                    
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
                    
                    appDelegate?.updateMenu()
                    return nil
                }
            }
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private func keyCodeToNumber(_ keyCode: Int64) -> Int? {
        switch keyCode {
        case 29: return 0  // 0 key for slot 10
        case 18: return 1
        case 19: return 2
        case 20: return 3
        case 21: return 4
        case 23: return 5
        case 22: return 6
        case 26: return 7
        case 28: return 8
        case 25: return 9
        default: return nil
        }
    }
}

