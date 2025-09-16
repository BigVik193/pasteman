import Cocoa
import Carbon

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
        
        for i in 1...9 {
            let item = NSMenuItem(title: "Clipboard \(i): Empty", action: nil, keyEquivalent: "")
            item.tag = i
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Clear All", action: #selector(clearAll), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func clearAll() {
        clipboardManager.clearAll()
        updateMenu()
    }
    
    func updateMenu() {
        guard let menu = statusItem.menu else { return }
        
        for i in 1...9 {
            if let item = menu.item(withTag: i) {
                let content = clipboardManager.getClipboard(at: i - 1)
                if let content = content {
                    let preview = String(content.prefix(50))
                    item.title = "Clipboard \(i): \(preview)\(content.count > 50 ? "..." : "")"
                } else {
                    item.title = "Clipboard \(i): Empty"
                }
            }
        }
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
    private var clipboards: [String?] = Array(repeating: nil, count: 9)
    private let pasteboard = NSPasteboard.general
    
    func saveToClipboard(at index: Int) {
        guard index >= 0 && index < 9 else { return }
        
        if let string = pasteboard.string(forType: .string) {
            clipboards[index] = string
            
            NSSound.beep()
            
            showNotification(title: "Clipboard \(index + 1) Saved", 
                           body: String(string.prefix(100)))
        }
    }
    
    func pasteFromClipboard(at index: Int) {
        guard index >= 0 && index < 9 else { return }
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
        guard index >= 0 && index < 9 else { return nil }
        return clipboards[index]
    }
    
    func clearAll() {
        clipboards = Array(repeating: nil, count: 9)
        showNotification(title: "All Clipboards Cleared", body: "")
    }
    
    func clearSlot(at index: Int) {
        guard index >= 0 && index < 9 else { return }
        
        if clipboards[index] != nil {
            clipboards[index] = nil
            showNotification(title: "Clipboard \(index + 1) Cleared", body: "")
        } else {
            NSSound.beep()
            showNotification(title: "Clipboard \(index + 1) Already Empty", body: "")
        }
    }
    
    func hasContent(at index: Int) -> Bool {
        guard index >= 0 && index < 9 else { return false }
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
            
            let isCmd = flags.contains(.maskCommand)
            let isShift = flags.contains(.maskShift)
            let isOption = flags.contains(.maskAlternate)
            
            if isCmd && isShift && !isOption {
                if let number = keyCodeToNumber(keyCode), number >= 1 && number <= 9 {
                    let slotIndex = number - 1
                    
                    if clipboardManager.hasContent(at: slotIndex) {
                        clipboardManager.pasteFromClipboard(at: slotIndex)
                    } else {
                        clipboardManager.saveToClipboard(at: slotIndex)
                    }
                    
                    appDelegate?.updateMenu()
                    return nil
                }
            }
            
            else if isCmd && isShift && isOption {
                if let number = keyCodeToNumber(keyCode), number >= 1 && number <= 9 {
                    clipboardManager.clearSlot(at: number - 1)
                    appDelegate?.updateMenu()
                    return nil
                }
            }
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private func keyCodeToNumber(_ keyCode: Int64) -> Int? {
        switch keyCode {
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