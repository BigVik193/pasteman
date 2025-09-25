//
//  Settings.swift
//  pasteman-app
//
//  Created by Trivikram Battalapalli on 9/25/25.
//

import Foundation

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