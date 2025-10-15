// Ajouter le disabled du bouton une fois cliquer

import SwiftUI
import AVFoundation

struct PointerBtn: View {
    @State private var audioPlayer: AVAudioPlayer?
    
    private func setupAudioPlayer() {
        guard let soundURL = Bundle.main.url(forResource: "mcdo-single", withExtension: "mp3") else {
            print("Impossible de trouver le fichier audio")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Erreur lors de l'initialisation du lecteur audio: \(error)")
        }
    }
    
    private func playSound() {
        audioPlayer?.play()
    }
    
    var body: some View {
        Button(action: {
            playSound()
            
        }) {
            VStack(spacing: 4) {
                Text("COLLECTER+")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("(Pointer le début du journée)")
                    .font(.system(size: 12))
                    .foregroundColor(.mainGreen.opacity(0.9))
            }
            .frame(maxWidth: 300)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(.mainYellow)
            )
        }
        .onAppear {
            setupAudioPlayer()
        }
    }
}

#Preview {
    PointerBtn()
}
