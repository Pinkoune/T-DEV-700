//
//  DeleteSpace.swift
//  frontend
//
//  Created by Jérémy Barcelo on 15/10/2025.
//

import SwiftUI

struct DeleteSpace: View {
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            ActionButton(
                title: "Supprimer mon compte",
                action: onDelete,
                backgroundColor: Color.red.opacity(0.8),
                foregroundColor: .white
            )
            .frame(height: 55)
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.red.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.red.opacity(0.4), lineWidth: 2)
                )
        )
        .padding(.bottom, 30)
    }
}
