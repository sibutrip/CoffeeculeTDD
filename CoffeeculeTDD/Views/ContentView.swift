//
//  ContentView.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/11/23.
//

import SwiftUI
import CloudKit

struct ContentView: View {
    @StateObject var coffeeculeManager = CoffeeculeManager<CloudKitService<CKContainer>>()
    @State private var isAuthenticating = true
    @State private var isAuthenticated = false
    @State private var couldNotAuthenticate = false
    @State private var errorText = ""
    var body: some View {
        VStack {
            if isAuthenticating {
                ProgressView()
            } else if isAuthenticated {
                CoffeeculeView()
            } else {
                VStack {
                    Text("Not authenticated")
                    Text(errorText)
                }
            }
        }
        .environmentObject(coffeeculeManager)
        .onAppear {
            Task {
                do {
                    let ckService = try await CloudKitService(with: ContainerInfo.container)
                    coffeeculeManager.ckService = ckService
                    isAuthenticated = true
                } catch {
                    couldNotAuthenticate = true
                    errorText = error.localizedDescription
                }
                isAuthenticating = false
            }
        }
        .alert("Could not authenticate", isPresented: $couldNotAuthenticate) {
            Button("OK") { }
        } message: {
            Text(errorText)
        }
    }
}

#Preview {
    ContentView()
}
