//
//  CoffeeculeView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/7/23.
//

import CloudKit
import SwiftUI

struct CoffeeculeView: View {
    @Environment(\.editMode) var editMode
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    let columns = [
        GridItem(.flexible(minimum: 10, maximum: .infinity)),
        GridItem(.flexible(minimum: 10, maximum: .infinity))
    ]
    @State var someoneElseBuying = false
    @State var isBuying = false
    @State var isDeletingCoffeecule = false
    @State private var errorText: String?
    @State private var isFetchingCoffeecules = true
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
                    AllMembersView(someoneElseBuying: $someoneElseBuying, isBuying: $isBuying)
                } else {
                    SomeoneElseBuying(someoneElseBuying: $someoneElseBuying, isBuying: $isBuying)
                }
            }
            .refreshable {
                Task {
//                    await coffeeculeManager.refreshData()
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
