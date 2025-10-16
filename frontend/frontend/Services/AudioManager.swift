//
//  AudioManager.swift
//  frontend
//
//  Created by Jérémy Barcelo on 16/10/2025.
//

import Foundation
import AVFoundation

final class AudioManager {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?
    private(set) var isPlaying: Bool = false

    private init() {}

    func startBackgroundAmbient() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            print("Erreur lors de la configuration du mp3: \(error)")
        }

        guard let url = Bundle.main.url(forResource: "mcdo-ambient", withExtension: "mp3") else {
            print("mcdo-ambient non trouvé.")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            self.player = player
            isPlaying = true
            print("Son ambient demarré.")
        } catch {
            print("Erreur lors du lancement du son ambient: \(error)")
        }
    }

    func stopBackgroundAmbient() {
        player?.stop()
        player = nil
        isPlaying = false
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            print("Erreur lors de la désactivation de l'audio: \(error)")
        }
    }
    
    func toggleBackgroundAmbient() {
        if isPlaying {
            stopBackgroundAmbient()
        } else {
            startBackgroundAmbient()
        }
    }
}
