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
    var body: some View {
        VStack {
            if isAuthenticating {
                ProgressView()
            } else {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
            }
        }
        .onAppear {
            Task {
                let ckService = try await CloudKitService(with: ContainerInfo.container)
                coffeeculeManager.ckService = ckService
                isAuthenticating = false
            }
        }
    }
}

#Preview {
    ContentView()
}
