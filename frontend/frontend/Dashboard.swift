//
//  Dashboard.swift
//  frontend
//
//  Created by Jérémy Barcelo on 13/10/2025.
//
import SwiftUI
import Foundation

struct DashboardView: View {
    @State private var recentActivities: [TimeEntry] = []
    
    var body: some View {
        ZStack {
            Color(.mainGreen)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Image(.mcApple)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 100, maxHeight: 60)
                
                HStack {
                    Text("Activité récente")
                        .font(.mcDoFont())
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                
                PointerCardMini()
                    .padding()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(sampleActivities) { activity in ActivityCard(activity: activity)
                        }
                    }
                    .padding(.horizontal)
                }

                    
                Spacer()
            }
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

struct ActivityCard: View {
    let activity: TimeEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Icône horloge
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                
                Image(systemName: "clock.fill")
                    .foregroundColor(.black)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.headline)
                    .foregroundColor(.black)
                
                if let startTime = activity.startTime {
                    Text("Arrivée : \(startTime)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
                if let endTime = activity.endTime {
                    Text("Départ : \(endTime)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(activity.timeSpent)
                    .font(.headline)
                    .foregroundColor(.black)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.mainYellow)
        )
        .padding(.horizontal, 15)
    }
}

#Preview {
    DashboardView()
}
