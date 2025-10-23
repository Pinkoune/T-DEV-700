//
//  frontendApp.swift
//  frontend
//
//  Created by Jérémy Barcelo on 08/10/2025.
//

import SwiftUI
import AVFoundation

@main
struct frontendApp: App {
    @State private var didStartAudio = false
    var body: some Scene {
        WindowGroup {
            Login()
                .onAppear {
                    if !didStartAudio {
                        AudioManager.shared.startBackgroundAmbient()
                        didStartAudio = true
                    }
                }
        }
    }
}
