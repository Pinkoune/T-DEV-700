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
            ZStack {
                Color(.mainGreen)
                    .ignoresSafeArea()
                
                VStack {
                    NavigationLink(destination: EmployeeHomePage()) {
                        Text("Aller à la page d'accueil")
                            .padding()
                            .background(Color.mainYellow)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .fontWeight(.bold)
                    }
                    .navigationBarBackButtonHidden(true)
                    .padding()
                }
            }
        }
    }
}
#Preview {
    ContentView()
}
