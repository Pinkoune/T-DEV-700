//
//  ActionButton.swift
//  frontend
//
//  Created by Jérémy Barcelo on 15/10/2025.
//

import SwiftUI

struct ActionButton: View {
    let title: String
    let action: () -> Void
    var backgroundColor: Color = .mainYellow
    var foregroundColor: Color = .white
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(backgroundColor)
                .cornerRadius(10)
        }
    }
}
