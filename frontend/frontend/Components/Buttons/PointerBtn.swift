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
    @State private var showPointsAnimation = false
    @State private var pointsOpacity = 0.0
    @State private var pointsYOffset: CGFloat = 0

    var body: some View {
        ZStack {
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
            
            // Animation Points
            if showPointsAnimation {
                Text("+10 Points")
                    .font(.custom("McDonaldsHelvetica", size: 24))
                    .foregroundColor(.mainYellow)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    .offset(y: pointsYOffset)
                    .opacity(pointsOpacity)
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
                    
                    // Trigger Animation
                    withAnimation(.easeOut(duration: 0.0)) {
                        showPointsAnimation = true
                        pointsOpacity = 1.0
                        pointsYOffset = 0 // Start at center (button)
                    }
                    
                    withAnimation(.easeOut(duration: 1.5)) {
                        pointsYOffset = 60 // Float down
                        pointsOpacity = 0.0
                    }
                    
                    // Cleanup animation state after it finishes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showPointsAnimation = false
                    }
                    
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
