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
    @State private var displayName = ""
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
    @State var noCoffeecules = false
    var hasBuyer: Bool {
        coffeeculeManager.selectedBuyer != nil
    }
    @State private var nameIsSubmitted = false
    var body: some View {
        NavigationStack {
            Group {
                if noCoffeecules {
                    ZStack {
                        if !nameIsSubmitted {
                            VStack {
                                Text("Welcome to Coffeecule!")
                                    .font(.title)
                                Text("How would you like your name to be displayed?")
                                    .foregroundStyle(Color.secondary)
                                HStack {
                                    TextField("Display Name", text: $displayName)
                                        .textFieldStyle(.roundedBorder)
                                        .onSubmit {
                                            coffeeculeManager.user?.name = displayName
                                            nameIsSubmitted = true
                                        }
                                        .submitLabel(.next)
                                    Button {
                                        coffeeculeManager.user?.name = displayName
                                        nameIsSubmitted = true
                                    } label: {
                                        Label("Submit", systemImage: "arrow.forward.circle")
                                            .labelStyle(.iconOnly)
                                    }
                                }
                                .padding()
                            }
//                            .transition(.opacity)
                            .transition(.asymmetric(insertion: .identity, removal: .move(edge: .leading)))
                        } else {
                            CreateOrJoinView()
//                                .transition(.opacity)
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .identity))
                        }
                    }
                    .animation(.default, value: nameIsSubmitted)
                } else {
                    if !someoneElseBuying {
                        AllMembersView(someoneElseBuying: $someoneElseBuying, isBuying: $isBuying, columnCount: $columnCount)
                    } else {
                        SomeoneElseBuying(someoneElseBuying: $someoneElseBuying, isBuying: $isBuying, columnCount: $columnCount)
                    }
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
                    if let selectedCoffeecule = coffeeculeManager.coffeecules.first {
                        coffeeculeManager.selectedCoffeecule = selectedCoffeecule
                        try await coffeeculeManager.fetchUsersInCoffeecule()
                        try await coffeeculeManager.fetchTransactionsInCoffeecule()
                        try coffeeculeManager.createUserRelationships()
                    } else {
                        noCoffeecules = true
                    }
                } catch {
                    errorText = error.localizedDescription
                }
                if coffeeculeManager.user?.name != "Test" {
                    nameIsSubmitted = true
                }
                isFetchingCoffeecules = false
            }
        }
        .onChangeiOS17Compatible(of: coffeeculeManager.coffeecules) { newValue in
            if !newValue.isEmpty { noCoffeecules = false }
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
