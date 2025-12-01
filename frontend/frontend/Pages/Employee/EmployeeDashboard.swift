//
//  Dashboard.swift
//  frontend
//
//  Created by Jérémy Barcelo on 13/10/2025.
//
import SwiftUI
import Foundation

struct EmployeeDashboard: View {
    @State private var recentActivities: [TimeEntry] = []
    @State private var userId = ""
    @State private var isLoading = false
    @State private var hasActiveEntry = false
    @State private var hoursWorked: Double = 0.0
    @State private var arrivalTime: Date?
    @State private var timer: Timer?
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            Color(.mainGreen)
                .edgesIgnoringSafeArea(.all)
            VStack {
                HeaderView(userType: .employee, title: "Activité récente")
                
                PointerCardMini(isActive: hasActiveEntry, hoursWorked: hoursWorked)
                    .padding(.horizontal, 16)
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .padding(.top, 50)
                } else if recentActivities.isEmpty {
                    Text("Aucune activité récente")
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 50)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(recentActivities) { activity in
                                ActivityCard(activity: activity)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 150)
                }
                
                Spacer()
            }
        }
        .onAppear {
            loadUserData()
            loadActivities()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                loadActivities()
                startTimer()
            } else {
                stopTimer()
            }
        }
    }
    
    private func loadUserData() {
        userId = UserDefaults.standard.string(forKey: "userId") ?? ""
    }
    
    private func loadActivities() {
        guard !userId.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                let entries = try await TimeEntryService.getTimeEntries(userId: userId, limit: 10)
                
                let activeResponse = try await TimeEntryService.getActiveTimeEntry(userId: userId)
                
                await MainActor.run {
                    isLoading = false
                    
                    recentActivities = entries.map { entry in
                        convertToTimeEntry(entry)
                    }
                    
                    hasActiveEntry = activeResponse.hasActiveEntry
                    if let activeEntry = activeResponse.timeEntry {
                        arrivalTime = activeEntry.arrival
                        hoursWorked = calculateHours(from: activeEntry.arrival)
                    } else {
                        arrivalTime = nil
                        hoursWorked = 0.0
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("Erreur de chargement des activités: \(error.localizedDescription)")
                }
            }
        }
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
    
    private func calculateHours(from arrival: Date) -> Double {
        let now = Date()
        let timeInterval = now.timeIntervalSince(arrival)
        return timeInterval / 3600.0
    }
    
    private func convertToTimeEntry(_ response: TimeEntryResponse) -> TimeEntry {
        let isActive = response.status == "active"
        let title = formatTitle(from: response.arrival, isActive: isActive)
        let subtitle = isActive ? "Journée en cours" : formatSubtitle(hours: response.hoursWorked)
        
        return TimeEntry(
            id: response.id ?? UUID().uuidString,
            title: title,
            subtitle: subtitle,
            startTime: formatTime(response.arrival),
            endTime: response.departure != nil ? formatTime(response.departure!) : nil,
            timeSpent: formatDuration(response.hoursWorked),
            isActive: isActive
        )
    }
    
    private func formatTitle(from date: Date, isActive: Bool) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Aujourd'hui"
        } else if calendar.isDateInYesterday(date) {
            return "Hier"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE dd/MM"
            formatter.locale = Locale(identifier: "fr_FR")
            return formatter.string(from: date).capitalized
        }
    }
    
    private func formatSubtitle(hours: Double?) -> String {
        guard let hours = hours else { return "Journée incomplète" }
        let h = Int(hours)
        return "Journée de \(h)h"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ hours: Double?) -> String {
        guard let hours = hours else { return "0:00" }
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return String(format: "%d:%02d", h, m)
    }
}

#Preview {
    EmployeeDashboard()
}
