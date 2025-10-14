//
//  ContentView.swift
//  frontend
//
//  Created by Jérémy Barcelo on 08/10/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: EmployeeHomePageView()) {
                    Text("Aller à la page d'accueil")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
}
#Preview {
    ContentView()
}
