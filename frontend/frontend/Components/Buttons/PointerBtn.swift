//
//  PointerBtn.swift
//  frontend
//
//  Created by Jérémy Barcelo on 13/10/2025.
//

import SwiftUI
import AVFoundation

struct PointerBtn: View {
    let userId: String
    @Binding var hasActiveEntry: Bool
    var onClockSuccess: () -> Void
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccess = false
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                handleClock()
            }) {
                VStack(spacing: 4) {
                    Text(hasActiveEntry ? "COLLECTER-" : "COLLECTER+")
                        .font(.custom("McDonaldsHelvetica", size: 20))
                        .foregroundColor(.white)
                    Text(hasActiveEntry ? "(Pointer la fin du journée)" : "(Pointer le début du journée)")
                        .font(.system(size: 12))
                        .foregroundColor(.mainGreen.opacity(0.9))
                }
                .frame(maxWidth: 300)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(isLoading ? Color.gray : Color.mainYellow)
                )
            }
            .disabled(isLoading)
            
            if showError && !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
            }
            
            if showSuccess {
                Text(hasActiveEntry ? "Arrivée pointée!" : " Départ pointé!")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(8)
            }
        }
        .onAppear {
            setupAudioPlayer()
        }
    }
    
    private func setupAudioPlayer() {
        guard let soundURL = Bundle.main.url(forResource: "mcdo-single", withExtension: "mp3") else {
            print("Impossible de trouver le fichier audio")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Erreur audio: \(error)")
        }
    }
    
    private func playSound() {
        audioPlayer?.play()
    }
    
    private func handleClock() {
        showError = false
        showSuccess = false
        errorMessage = ""
        isLoading = true
        
        Task {
            do {
                let response = try await TimeEntryService.clock(userId: userId)
                
                await MainActor.run {
                    isLoading = false
                    playSound()
                    hasActiveEntry = (response.status == "active")
                    showSuccess = true
                    print("Pointage réussi: \(response.status)")
                    
                    // Add loyalty points
                    Task {
                        try? await LoyaltyService.addPoints(userId: userId, points: 10)
                    }
                    
                    onClockSuccess()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showSuccess = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                    print("Erreur pointage: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    PointerBtn(
        userId: "preview-id",
        hasActiveEntry: .constant(false),
        onClockSuccess: {}
    )
}
