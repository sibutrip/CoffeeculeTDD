//
//  DebugCoffeeculeView.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/23/23.
//

import SwiftUI
import CloudKit

struct DebugCoffeeculeView: View {
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
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
    
    var body: some View {
        VStack {
            Spacer()
            if isFetchingCoffeecules {
                LottieViewAnimated()
            } else if !coffeeculeManager.coffeecules.isEmpty {
                Picker("Select A Coffeecule", selection: $coffeeculeManager.selectedCoffeecule) {
                    ForEach(coffeeculeManager.coffeecules) { coffeecule in
                        Text(coffeecule.id).tag(Optional(coffeecule))
                    }
                }
            }
            Button("Create coffeecule") {
                Task {
                    do {
                        try await coffeeculeManager.createCoffeecule(with: "Test name")
                    } catch {
                        errorText = error.localizedDescription
                    }
                }
            }
            Spacer()
            VStack {
                Text("Users In selected cule")
                ForEach(coffeeculeManager.usersInSelectedCoffeecule) { user in
                    Text(user.name)
                }
            }
            Spacer()
            VStack {
                Text("Selected Users")
                ForEach(coffeeculeManager.usersInSelectedCoffeecule) { user in
                    Button(user.name) {
                        if coffeeculeManager.selectedUsers.contains(where: {$0 == user}) {
                            coffeeculeManager.selectedUsers = coffeeculeManager.selectedUsers.filter { $0 != user }
                        } else {
                            coffeeculeManager.selectedUsers.append(user)
                        }
                        try? coffeeculeManager.createUserRelationships()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(coffeeculeManager.selectedUsers.contains(where: {$0 == user}) ? Color.green : Color.red)
                }
            }
            Spacer()
            VStack {
                Text("Transactions:")
                ForEach(coffeeculeManager.transactionsInSelectedCoffeecule) { transaction in
                    HStack {
                        Text("Buyer: \(transaction.secondParent?.name ?? "")")
                        Spacer()
                        Text("Receiver: \(transaction.thirdParent?.name ?? "")")
                    }
                }
                Text(coffeeculeManager.selectedBuyer?.name ?? "")
                Button("Add transaction") {
                    Task {
                        try await coffeeculeManager.addTransaction()
                    }
                }
            }
            Spacer()
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
        .padding(.horizontal)
    }
}

#Preview {
    DebugCoffeeculeView()
}
