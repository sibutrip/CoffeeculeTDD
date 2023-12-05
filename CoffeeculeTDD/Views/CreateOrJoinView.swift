//
//  CreateOrJoinView.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 12/5/23.
//

import SwiftUI
import CloudKit

struct CreateOrJoinView: View {
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    @State private var isCreatingCoffeecule = false
    @State private var isJoiningCoffeecule = false
    @Environment(\.dismiss) var dismiss
    
    @State private var coffeeculeName = ""
    @State private var inviteCode = ""
    
    var body: some View {
        EqualWidthVStackLayout(spacing: 10) {
            Button {
                isCreatingCoffeecule = true
            } label: {
                Text("Create A Coffeecule")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            Button {
                isJoiningCoffeecule = true
            } label: {
                Text("Join A Coffeecule")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .alert("Create A Coffeecule", isPresented: $isCreatingCoffeecule) {
            VStack {
                TextField("Coffeecule Display Name", text: $coffeeculeName)
                    .autocorrectionDisabled()
                HStack {
                    Button("Create") {
                        Task {
                            do {
                                try await coffeeculeManager.createCoffeecule(with: coffeeculeName)
                                try await coffeeculeManager.fetchUsersInCoffeecule()
                                try await coffeeculeManager.fetchTransactionsInCoffeecule()
                                try coffeeculeManager.createUserRelationships()
                            } catch {
                                fatalError(error.localizedDescription)
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                }
            }
        }
        .alert("Join A Coffeecule", isPresented: $isJoiningCoffeecule) {
            VStack {
                TextField("Coffeecule Short Code",
                          text: Binding { inviteCode
                } set: { newValue in
                    inviteCode = newValue.uppercased()
                })
                .autocorrectionDisabled()
                HStack {
                    Button("Join") {
                        Task {
                            do {
                                let inviteCode = inviteCode.uppercased()
                                try await coffeeculeManager.joinCoffeecule(withInviteCode: inviteCode)
                                try await coffeeculeManager.fetchUsersInCoffeecule()
                                try await coffeeculeManager.fetchTransactionsInCoffeecule()
                                try coffeeculeManager.createUserRelationships()
                                dismiss()
                            } catch {
                                fatalError(error.localizedDescription)
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                }
            }
        }
    }
}

#Preview {
    CreateOrJoinView()
}
