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
    
    var body: some View {
        NavigationStack {
            ZStack {
            Color(.mainGreen)
                .edgesIgnoringSafeArea(.all)
            VStack {
                HeaderView(userType: .employee, title: "Activité récente")
                
                PointerCardMini()
                    .padding(.horizontal, 16)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(sampleActivities) { activity in ActivityCard(activity: activity)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 30)
                .padding(.bottom, 150)

                    
                Spacer()
            }
            VStack{
                Spacer()
                Navbar(userType: .employee)
                    .ignoresSafeArea(edges: .all)
                    
                  .padding(.bottom, 0)

            }
            .edgesIgnoringSafeArea(.all)
        }
        .navigationBarBackButtonHidden(true)
    }
    }
    
    private var sampleActivities: [TimeEntry] {
            [
                TimeEntry(
                    id: "1",
                    title: "Aujourd'hui",
                    subtitle: "Journée en cours",
                    startTime: "8:30",
                    endTime: nil,
                    timeSpent: "7:10",
                    isActive: true
                ),
                TimeEntry(
                    id: "2",
                    title: "Hier",
                    subtitle: "Journée de 9h",
                    startTime: "8:30",
                    endTime: "17:30",
                    timeSpent: "7:17",
                    isActive: false
                ),
                TimeEntry(
                    id: "3",
                    title: "Mercredi 08/10",
                    subtitle: "Journée de 9h",
                    startTime: "8:30",
                    endTime: "17:30",
                    timeSpent: "7:30",
                    isActive: false
                ),
                TimeEntry(
                    id: "4",
                    title: "Mardi 07/10",
                    subtitle: "Journée de 9h",
                    startTime: "8:30",
                    endTime: "17:30",
                    timeSpent: "7:02",
                    isActive: false
                )
            ]
        }
}

#Preview {
    EmployeeDashboard()
}
