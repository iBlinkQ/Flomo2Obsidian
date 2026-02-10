//
//  Flomo2ObsidianApp.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import SwiftUI

@main
struct Flomo2ObsidianApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 600, minHeight: 400)
        }
        .windowResizability(.contentSize)
    }
}
