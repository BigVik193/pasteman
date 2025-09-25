//
//  SettingsView.swift
//  pasteman-app
//
//  Created by Trivikram Battalapalli on 9/25/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var keyBindingManager = KeyBindingManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Pasteman Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Keyboard Shortcuts")
                    .font(.headline)
                
                Text("Pasteman uses keyboard shortcuts to save and paste clipboard content:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Save to clipboard slot:")
                            .fontWeight(.medium)
                        Text("⌘⇧1-0")
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Text("Paste from clipboard slot:")
                            .fontWeight(.medium)
                        Text("⌘1-0")
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                .padding(.leading, 16)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Permissions")
                    .font(.headline)
                
                Text("Pasteman requires accessibility permissions to monitor global keyboard shortcuts and simulate paste operations.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("Open Accessibility Settings") {
                    openAccessibilitySettings()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("About")
                    .font(.headline)
                
                Text("Pasteman - Advanced Clipboard Manager")
                    .fontWeight(.medium)
                
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Manage multiple clipboard slots with keyboard shortcuts. Save frequently used text snippets and access them instantly.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 500, height: 400)
    }
    
    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    SettingsView()
}
