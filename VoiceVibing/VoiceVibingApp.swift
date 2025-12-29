//
//  VoiceVibingApp.swift
//  VoiceVibing
//
//  Created by Zaid Erekat on 12/28/25.
//

import SwiftUI

@main
struct VoiceVibingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
