//
//  PointerCard.swift
//  frontend
//
//  Created by Jérémy Barcelo on 13/10/2025.
//

import SwiftUI

struct PointerCard: View {
    let userId: String
    
    @State private var hasActiveEntry = false
    @State private var arrivalTime: Date?
    @State private var hoursWorked: Double = 0.0
    @State private var isLoading = false
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DynamicStatusBadge(isActive: hasActiveEntry)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
            
            DynamicTimeInfoView(
                arrivalTime: arrivalTime,
                hoursWorked: hoursWorked,
                isActive: hasActiveEntry
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            DynamicDateLabel()
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.mainGreen, .second]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(
            color: .white.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
        .onAppear {
            loadActiveTimeEntry()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func loadActiveTimeEntry() {
        isLoading = true
        
        Task {
            do {
                let response = try await TimeEntryService.getActiveTimeEntry(userId: userId)
                
                await MainActor.run {
                    isLoading = false
                    hasActiveEntry = response.hasActiveEntry
                    
                    if let timeEntry = response.timeEntry {
                        arrivalTime = timeEntry.arrival
                        hoursWorked = calculateHours(from: timeEntry.arrival)
                    } else {
                        arrivalTime = nil
                        hoursWorked = 0.0
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("Erreur chargement: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func calculateHours(from arrival: Date) -> Double {
        let now = Date()
        let timeInterval = now.timeIntervalSince(arrival)
        return timeInterval / 3600.0
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            updateHoursWorked()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateHoursWorked() {
        if let arrival = arrivalTime, hasActiveEntry {
            hoursWorked = calculateHours(from: arrival)
        }
    }
}

struct DynamicStatusBadge: View {
    let isActive: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.mainYellow)
                .font(.system(size: 14))
            Text(isActive ? "En cours" : "Pas pointé")
                .font(.custom("McDonaldsHelvetica", size: 16))
                .foregroundColor(.white)
            Spacer()
            Circle()
                .fill(isActive ? Color.green : Color.red)
                .frame(width: 12, height: 12)
        }
    }
}

struct DynamicTimeInfoView: View {
    let arrivalTime: Date?
    let hoursWorked: Double
    let isActive: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            TimerCircle(hours: formatHours(hoursWorked))
            
            VStack(alignment: .leading, spacing: 12) {
                TimeDetail(
                    label: "Heure d'arrivée",
                    time: arrivalTime != nil ? formatTime(arrivalTime!) : "-"
                )
                
                TimeDetail(
                    label: "Heure de départ",
                    time: "-"
                )
            }
            
            Spacer()
        }
    }
    
    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        return "\(h) h"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct DynamicDateLabel: View {
    var body: some View {
        HStack {
            Spacer()
            Text(formatDate(Date()))
                .font(.custom("McDonaldsHelvetica", size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    PointerCard(userId: "preview-id")
}
