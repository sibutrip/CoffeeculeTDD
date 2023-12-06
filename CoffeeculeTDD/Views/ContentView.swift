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
                LottieViewAnimated()
                    .transition(.opacity)
            } else if isAuthenticated {
                CoffeeculeView()
            } else {
                VStack {
                    Text("Not authenticated")
                    Text(errorText)
                }
            }
        }
        .coordinateSpace(name: "refreshable")
        .animation(.default, value: isAuthenticating)
        .environmentObject(coffeeculeManager)
        .onAppear {
            Task {
                do {
                    let ckService = try await CloudKitService(with: ContainerInfo.container)
                    coffeeculeManager.ckService = ckService
                    coffeeculeManager.user = await ckService.user
                    isAuthenticated = true
                    try await coffeeculeManager.fetchCoffeecules()
                    if let selectedCoffeecule = coffeeculeManager.coffeecules.first {
                        coffeeculeManager.selectedCoffeecule = selectedCoffeecule
                        try await coffeeculeManager.fetchUsersInCoffeecule()
                        try await coffeeculeManager.fetchTransactionsInCoffeecule()
                        try coffeeculeManager.createUserRelationships()
                    }
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
