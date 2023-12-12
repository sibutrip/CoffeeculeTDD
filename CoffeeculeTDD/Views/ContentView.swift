//
//  ContentView.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/11/23.
//

import SwiftUI
import CloudKit

struct ContentView: View, ErrorAlertable {
    @StateObject var coffeeculeManager = CoffeeculeManager<CloudKitService<CKContainer>>()
    @State private var isAuthenticated = false
    @State var errorTitle: String?
    @State var errorMessage: String?
    @State var isLoading = true
    
    var body: some View {
        VStack {
            if isLoading {
                LottieViewAnimated()
                    .transition(.opacity)
            } else if isAuthenticated {
                CoffeeculeView()
            } else {
                VStack {
                    Text("Not authenticated")
                    Text(errorTitle ?? "")
                    Text(errorMessage ?? "")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .coordinateSpace(name: "refreshable")
        .animation(.default, value: isLoading)
        .environmentObject(coffeeculeManager)
        .onAppear {
            displayAlertIfFailsAsync {
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
            }
        }
        .displaysAlertIfActionFails(for: self)
    }
}

#Preview {
    ContentView()
}
