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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}
