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
    @State private var showConfirmation = false
    @State private var isTemporarilyBlocked = false

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Button(action: {
                    showConfirmation = true
                }) {
                    VStack(spacing: 4) {
                        Text(hasActiveEntry ? "COLLECTER-": "COLLECTER+").font(.custom("McDonaldsHelvetica", size: 20)).foregroundColor(.white)
                        Text(hasActiveEntry ? "(Pointer la fin de journée)": "(Pointer le début de journée)").font(.system(size: 12)).foregroundColor(.mainGreen.opacity(0.9))
                    }.frame(maxWidth: 300).frame(height: 60).background(
                        RoundedRectangle(cornerRadius: 30).fill(isButtonBlocked() ? Color.gray: (isLoading ? Color.gray: Color.mainYellow))
                    )
                }.disabled(isLoading || isButtonBlocked()).alert("Confirmation", isPresented: $showConfirmation) {
                    Button("Annuler", role: .cancel) {
                    }
                    Button("Oui, je confirme") {
                        handleClock()
                    }
                } message: {
                    Text(hasActiveEntry ? "Voulez-vous vraiment pointer ?": "Voulez-vous vraiment pointer ?")
                }

                if isButtonBlocked() {
                    Text(getBlockMessage()).font(.caption).foregroundColor(.white.opacity(0.7))
                }

                if showError && !errorMessage.isEmpty {
                    Text(errorMessage).foregroundColor(.red).font(.subheadline).padding().background(Color.white.opacity(0.9)).cornerRadius(8)
                }

                if showSuccess {
                    Text(hasActiveEntry ? "Arrivée pointée!": " Départ pointé!").foregroundColor(.white).font(.subheadline).padding().background(Color.green.opacity(0.8)).cornerRadius(8)
                }
            }

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
            checkCooldown()
        }
    }
    

    private func isButtonBlocked() -> Bool {
        if isTemporarilyBlocked {
            return true
        }

        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        _ = calendar.component(.minute, from: date)

        if hasActiveEntry {
        } else {
            if let lastClockOut = UserDefaults.standard.object(forKey: "lastClockOutTime_\(userId)") as? Date {
                if calendar.isDateInToday(lastClockOut) {
                    let lastOutHour = calendar.component(.hour, from: lastClockOut)
                    
                    if lastOutHour < 13 && hour < 13 {
                        return true
                    }
                    
                    if lastOutHour >= 13 && hour >= 13 {
                        return true
                    }
                }
            }

            if hour >= 12 && hour < 13 {
                return true
            }
        }

        return false
    }

    private func getBlockMessage() -> String {
        if isTemporarilyBlocked {
            return "Veuillez patienter 10 secondes..."
        }

        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        if hasActiveEntry {
        } else {
            if let lastClockOut = UserDefaults.standard.object(forKey: "lastClockOutTime_\(userId)") as? Date {
                if calendar.isDateInToday(lastClockOut) {
                    let lastOutHour = calendar.component(.hour, from: lastClockOut)
                    
                    if lastOutHour < 13 && hour < 13 {
                        return "Matinée terminée"
                    }
                    if lastOutHour >= 13 && hour >= 13 {
                        return "Journée terminée"
                    }
                }
            }

            if hour >= 12 && hour < 13 {
                 return "Retour bloqué avant 13h00"
            }
        }
        return ""
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
    
    private func checkCooldown() {
        if let lastClock = UserDefaults.standard.object(forKey: "lastClockTime_\(userId)") as? Date {
            let timePassed = Date().timeIntervalSince(lastClock)
            if timePassed < 10 {
                isTemporarilyBlocked = true
                DispatchQueue.main.asyncAfter(deadline: .now() + (10 - timePassed)) {
                    isTemporarilyBlocked = false
                }
            }
        }
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

                    UserDefaults.standard.set(Date(), forKey: "lastClockTime_\(userId)")
                    
                    if !hasActiveEntry {
                        UserDefaults.standard.set(Date(), forKey: "lastClockOutTime_\(userId)")
                    }

                    isTemporarilyBlocked = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        isTemporarilyBlocked = false
                    }

                    withAnimation(.easeOut(duration: 0.0)) {
                        showPointsAnimation = true
                        pointsOpacity = 1.0
                        pointsYOffset = 0
                    }

                    withAnimation(.easeOut(duration: 1.5)) {
                        pointsYOffset = 60
                        pointsOpacity = 0.0
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showPointsAnimation = false
                    }

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