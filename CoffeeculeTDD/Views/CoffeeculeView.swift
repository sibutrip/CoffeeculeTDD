//
//  CoffeeculeView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/7/23.
//

import CloudKit
import SwiftUI

struct CoffeeculeView: View {
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    @State var someoneElseBuying = false
    @State var isBuying = false
    @State var isDeletingCoffeecule = false
    @State private var errorText: String?
    @State private var isFetchingCoffeecules = true
    @AppStorage("Column Count") var columnCount = 2
    var showingError: Binding<Bool> {
        Binding {
            errorText != nil
        } set: { isShowingError in
            if !isShowingError {
                errorText = nil
            }
        }
    }
    var hasBuyer: Bool {
        coffeeculeManager.selectedBuyer != nil
    }
    var body: some View {
        NavigationStack {
            Group {
                if !someoneElseBuying {
                    AllMembersView(someoneElseBuying: $someoneElseBuying, isBuying: $isBuying, columnCount: $columnCount)
                } else {
                    SomeoneElseBuying(someoneElseBuying: $someoneElseBuying, isBuying: $isBuying, columnCount: $columnCount)
                }
            }
            .refreshable {
                Task {
                    do {
                        try await coffeeculeManager.fetchUsersInCoffeecule()
                        try await coffeeculeManager.fetchTransactionsInCoffeecule()
                    } catch {
                        errorText = error.localizedDescription
                    }
                }
            }
        }
        .onChange(of: coffeeculeManager.selectedCoffeecule, { _, newValue in
            Task {
                do {
                    coffeeculeManager.usersInSelectedCoffeecule = []
                    try await coffeeculeManager.fetchUsersInCoffeecule()
                    try await coffeeculeManager.fetchTransactionsInCoffeecule()
                    try coffeeculeManager.createUserRelationships()
                } catch {
                    errorText = error.localizedDescription
                }
            }
        })
        .onAppear {
            Task {
                do {
                    try await coffeeculeManager.fetchCoffeecules()
                    coffeeculeManager.selectedCoffeecule = coffeeculeManager.coffeecules.first
                    try coffeeculeManager.createUserRelationships()
                } catch {
                    errorText = error.localizedDescription
                }
                isFetchingCoffeecules = false
            }
        }
        .alert("Uh oh", isPresented: showingError, actions: {
            Button("ok") { }
        }, message: {
            Text(errorText ?? "")
        })
        .alert("Is \(coffeeculeManager.selectedBuyer?.name ?? "") buying coffee?", isPresented: $isBuying) {
            HStack {
                Button("Yes") {
                    Task(priority: .userInitiated) {
                        try await coffeeculeManager.addTransaction()
                    }
                    someoneElseBuying = false
                }
                Button("Cancel", role: .cancel) {
                    isBuying = false
                }
            }
        }
        .animation(.default, value: someoneElseBuying)
    }
}
