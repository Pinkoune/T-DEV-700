//
//  EmployeeHomepage.swift
//  frontend
//
//  Created by Jérémy Barcelo on 13/10/2025.
//

import SwiftUI

struct EmployeeHomePage: View {
    @State private var firstName = ""
    @State private var userId = ""
    @State private var hasActiveEntry = false
    @State private var refreshKey = UUID()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            Color(.mainGreen)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HeaderView(
                    userType: .employee,
                    title: "Bonjour \(firstName),"
                )
                
                PointerCard(userId: userId)
                    .id(refreshKey)
                    .padding(.horizontal, 16)
                
                PointerBtn(
                    userId: userId,
                    hasActiveEntry: $hasActiveEntry,
                    onClockSuccess: {
                        refreshKey = UUID()
                    }
                )
                .padding(.horizontal, 40)
                .padding(.top, 30)
                
                Spacer()
            }
        }
        .onAppear {
            loadUserData()
            refreshData()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                refreshData()
            }
        }
    }
    
    private func refreshData() {
        refreshKey = UUID()
        loadActiveStatus()
    }
    
    private func loadUserData() {
        firstName = UserDefaults.standard.string(forKey: "userFirstName") ?? "Utilisateur"
        userId = UserDefaults.standard.string(forKey: "userId") ?? ""
        
        print("Données chargées - Prénom: \(firstName), ID: \(userId)")
        
        loadActiveStatus()
    }
    
    private func loadActiveStatus() {
        guard !userId.isEmpty else { return }
        
        Task {
            do {
                let response = try await TimeEntryService.getActiveTimeEntry(userId: userId)
                await MainActor.run {
                    hasActiveEntry = response.hasActiveEntry
                }
            } catch {
                // print("Erreur chargement statut: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    EmployeeHomePage()
}
