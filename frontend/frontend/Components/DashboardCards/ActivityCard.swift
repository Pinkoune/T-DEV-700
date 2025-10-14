//
//  ActivityCard.swift
//  frontend
//
//  Created by Jérémy Barcelo on 14/10/2025.
//
import SwiftUI

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
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
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
                    .fontWeight(.bold)
                    .foregroundColor(.white)
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
