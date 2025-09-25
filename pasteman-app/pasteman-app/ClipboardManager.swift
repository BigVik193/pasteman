//
//  ClipboardManager.swift
//  pasteman-app
//
//  Created by Trivikram Battalapalli on 9/25/25.
//

import Cocoa
import Combine

class ClipboardManager: ObservableObject {
    @Published private var clipboards: [String?] = Array(repeating: nil, count: 10)
    private let pasteboard = NSPasteboard.general
    
    init() {
        // No notification permissions needed - just use console logging like original
    }
    
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
        // Simple console logging like the original
        print("\(title): \(body)")
    }
}