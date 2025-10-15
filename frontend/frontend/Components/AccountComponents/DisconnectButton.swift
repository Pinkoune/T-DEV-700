//
//  DisconnectButton.swift
//  frontend
//
//  Created by Jérémy Barcelo on 15/10/2025.
//

import SwiftUI

struct DisconnectButton: View {
    let onDisconnect: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            ActionButton(
                title: "Se déconnecter",
                action: onDisconnect,
                backgroundColor: .gray,
                foregroundColor: .white
            )
            .frame(height: 55)
        }
        .padding(25)
        .padding(.bottom, 5)
        .padding(.top, -40)
    }
}
