//
//  pasteman_appApp.swift
//  pasteman-app
//
//  Created by Trivikram Battalapalli on 9/25/25.
//

import SwiftUI

@main
struct PastemanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Empty scene - all functionality handled in AppDelegate
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
                .hidden()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
