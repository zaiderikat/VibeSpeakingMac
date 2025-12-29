//
//  VoiceVibingApp.swift
//  VoiceVibing
//
//  Created by Zaid Erekat on 12/28/25.
//

import SwiftUI

@main
struct VoiceVibingApp: App {
    @StateObject private var appState: AppState
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)
        appDelegate.attach(appState: state)
    }

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
        .defaultSize(width: 420, height: 360)
    }
}
