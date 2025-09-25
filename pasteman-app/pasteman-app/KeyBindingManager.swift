//
//  KeyBindingManager.swift
//  pasteman-app
//
//  Created by Trivikram Battalapalli on 9/25/25.
//

import Cocoa
import Carbon
import Combine

protocol KeyBindingManagerDelegate: AnyObject {
    func saveToClipboard(at slot: Int)
    func pasteFromClipboard(at slot: Int)
    func clearClipboard(at slot: Int)
}

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
        case 1: return "s"
        case 2: return "d"
        case 3: return "f"
        case 4: return "h"
        case 5: return "g"
        case 6: return "z"
        case 7: return "x"
        case 8: return "c"
        case 9: return "v"
        case 11: return "b"
        case 12: return "q"
        case 13: return "w"
        case 14: return "e"
        case 15: return "r"
        case 16: return "y"
        case 17: return "t"
        case 31: return "o"
        case 32: return "u"
        case 34: return "i"
        case 35: return "p"
        case 37: return "l"
        case 38: return "j"
        case 40: return "k"
        case 45: return "n"
        case 46: return "m"
        default: return nil
        }
    }
}

class KeyBindingManager: ObservableObject {
    @Published var keyBindings: [KeyBinding] = []
    weak var delegate: KeyBindingManagerDelegate?
    
    init() {
        loadDefaultKeyBindings()
        loadKeyBindingsFromFile()
    }
    
    private func loadDefaultKeyBindings() {
        keyBindings = [
            // Save shortcuts (Cmd+Shift+1-0)
            KeyBinding(modifiers: ["cmd", "shift"], key: "1", action: "save", slot: 1),
            KeyBinding(modifiers: ["cmd", "shift"], key: "2", action: "save", slot: 2),
            KeyBinding(modifiers: ["cmd", "shift"], key: "3", action: "save", slot: 3),
            KeyBinding(modifiers: ["cmd", "shift"], key: "4", action: "save", slot: 4),
            KeyBinding(modifiers: ["cmd", "shift"], key: "5", action: "save", slot: 5),
            KeyBinding(modifiers: ["cmd", "shift"], key: "6", action: "save", slot: 6),
            KeyBinding(modifiers: ["cmd", "shift"], key: "7", action: "save", slot: 7),
            KeyBinding(modifiers: ["cmd", "shift"], key: "8", action: "save", slot: 8),
            KeyBinding(modifiers: ["cmd", "shift"], key: "9", action: "save", slot: 9),
            KeyBinding(modifiers: ["cmd", "shift"], key: "0", action: "save", slot: 10),
            
            // Paste shortcuts (Cmd+1-0)
            KeyBinding(modifiers: ["cmd"], key: "1", action: "paste", slot: 1),
            KeyBinding(modifiers: ["cmd"], key: "2", action: "paste", slot: 2),
            KeyBinding(modifiers: ["cmd"], key: "3", action: "paste", slot: 3),
            KeyBinding(modifiers: ["cmd"], key: "4", action: "paste", slot: 4),
            KeyBinding(modifiers: ["cmd"], key: "5", action: "paste", slot: 5),
            KeyBinding(modifiers: ["cmd"], key: "6", action: "paste", slot: 6),
            KeyBinding(modifiers: ["cmd"], key: "7", action: "paste", slot: 7),
            KeyBinding(modifiers: ["cmd"], key: "8", action: "paste", slot: 8),
            KeyBinding(modifiers: ["cmd"], key: "9", action: "paste", slot: 9),
            KeyBinding(modifiers: ["cmd"], key: "0", action: "paste", slot: 10),
        ]
    }
    
    func handleKeyEvent(flags: CGEventFlags, keyCode: Int64) {
        for binding in Settings.shared.keyBindings {
            if binding.matches(flags: flags, keyCode: keyCode) {
                executeAction(binding)
                break
            }
        }
    }
    
    private func executeAction(_ binding: KeyBinding) {
        guard let slot = binding.slot else { return }
        let index = slot - 1 // Convert to 0-based index
        
        switch binding.action {
        case "save_or_paste":
            // Check if slot has content, if so paste, otherwise save
            if let clipboardManager = delegate as? AppDelegate {
                if clipboardManager.clipboardManager.hasContent(at: index) {
                    delegate?.pasteFromClipboard(at: index)
                } else {
                    delegate?.saveToClipboard(at: index)
                }
            }
        case "clear":
            delegate?.clearClipboard(at: index)
        default:
            break
        }
    }
    
    func getKeyBinding(for action: String, slot: Int) -> KeyBinding? {
        return Settings.shared.keyBindings.first { $0.action == action && $0.slot == slot }
    }
    
    private func loadKeyBindingsFromFile() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let configURL = documentsPath.appendingPathComponent("pasteman-keybindings.json")
        
        guard let data = try? Data(contentsOf: configURL),
              let loadedBindings = try? JSONDecoder().decode([KeyBinding].self, from: data) else {
            return
        }
        
        keyBindings = loadedBindings
    }
    
    func saveKeyBindingsToFile() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let configURL = documentsPath.appendingPathComponent("pasteman-keybindings.json")
        
        guard let data = try? JSONEncoder().encode(keyBindings) else { return }
        try? data.write(to: configURL)
    }
}