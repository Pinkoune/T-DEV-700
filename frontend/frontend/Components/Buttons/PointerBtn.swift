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
    @State private var todayEntries: [TimeEntryResponse] = []

    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                showConfirmation = true
            }) {
                VStack(spacing: 4) {
                    Text(hasActiveEntry ? "COLLECTER-" : "COLLECTER+")
                        .font(.custom("McDonaldsHelvetica", size: 20))
                        .foregroundColor(.white)

                    Text(hasActiveEntry ? "(Pointer la fin de journée)" : "(Pointer le début de journée)")
                        .font(.system(size: 12))
                        .foregroundColor(.mainGreen.opacity(0.9))
                }
                .frame(maxWidth: 300)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(isButtonBlocked() ? Color.gray : (isLoading ? Color.gray : Color.mainYellow))
                )
            }
            .disabled(isLoading || isButtonBlocked())
            .alert("Confirmation", isPresented: $showConfirmation) {
                Button("Annuler", role: .cancel) { }
                Button("Oui, je confirme") {
                    handleClock()
                }
            } message: {
                Text(hasActiveEntry ? "Voulez-vous vraiment pointer ?" : "Voulez-vous vraiment pointer ?")
            }

            if isButtonBlocked() {
                Text(getBlockMessage())
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            if showError && !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
            }

            if showSuccess {
                Text(hasActiveEntry ? "Arrivée pointée!" : "Départ pointé!")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(8)
            }
        }
        .onAppear {
            setupAudioPlayer()
            loadHistory()
        }
    }
    
    private func loadHistory() {
        Task {
            do {
                let entries = try await TimeEntryService.getTimeEntries(userId: userId, limit: 10)
                await MainActor.run {
                    todayEntries = entries.filter { Calendar.current.isDateInToday($0.arrival) }
                }
            } catch { }
        }
    }

    private func isButtonBlocked() -> Bool {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)

        if hasActiveEntry {
            if hour < 11 {
                return true
            }
            if hour == 11 && minute < 30 {
                return true
            }
            if hour >= 13 && hour < 16 {
                return true
            }
        } else {
            let morningEntry = todayEntries.first { Calendar.current.component(.hour, from: $0.arrival) < 13 }
            let afternoonEntry = todayEntries.first { Calendar.current.component(.hour, from: $0.arrival) >= 13 }

            if hour < 13 {
                if morningEntry != nil {
                    return true
                }
            } else {
                if afternoonEntry != nil {
                    return true
                }
            }
        }
        return false
    }

    private func getBlockMessage() -> String {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        if hasActiveEntry {
            if hour < 12 {
                return "Départ bloqué avant 11h30"
            }
            if hour >= 13 {
                return "Départ bloqué avant 16h00"
            }
        } else {
            let morningEntry = todayEntries.first { Calendar.current.component(.hour, from: $0.arrival) < 13 }
            let afternoonEntry = todayEntries.first { Calendar.current.component(.hour, from: $0.arrival) >= 13 }

            if hour < 13 && morningEntry != nil {
                return "Session du matin déjà effectuée"
            }
            if hour >= 13 && afternoonEntry != nil {
                return "Session de l'après-midi déjà effectuée"
            }
        }
        return ""
    }

    private func setupAudioPlayer() {
        guard let soundURL = Bundle.main.url(forResource: "mcdo-single", withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
        } catch { }
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

                    loadHistory()
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