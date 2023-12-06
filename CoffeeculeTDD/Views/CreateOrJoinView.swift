//
//  CreateOrJoinView.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 12/5/23.
//

import SwiftUI
import CloudKit
import Combine

struct CreateOrJoinView: View {
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    @State private var isCreatingCoffeecule = false
    @State private var isJoiningCoffeecule = false
    @Environment(\.dismiss) var dismiss
    
    @State private var coffeeculeName = ""
    @State private var inviteCode = ""
    
    @Binding var isLoading: Bool
    
    @State private var errorText: String?
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
                            isLoading = true
                            Task {
                                do {
                                    try await coffeeculeManager.createCoffeecule(with: coffeeculeName)
                                    try await coffeeculeManager.fetchUsersInCoffeecule()
                                    try await coffeeculeManager.fetchTransactionsInCoffeecule()
                                    try coffeeculeManager.createUserRelationships()
                                } catch {
                                    errorText = error.localizedDescription
                                }
                                isLoading = false
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
                    .onReceive(Just(inviteCode)) { _ in
                        if inviteCode.count > 6 {
                            inviteCode = String(inviteCode.prefix(6))
                        }
                    }
                    .autocorrectionDisabled()
                    HStack {
                        Button("Join") {
                            isLoading = true
                            Task {
                                do {
                                    let inviteCode = inviteCode.uppercased()
                                    try await coffeeculeManager.joinCoffeecule(withInviteCode: inviteCode)
                                    try await coffeeculeManager.fetchUsersInCoffeecule()
                                    try await coffeeculeManager.fetchTransactionsInCoffeecule()
                                    try coffeeculeManager.createUserRelationships()
                                } catch {
                                    errorText = error.localizedDescription
                                }
                                isLoading = false
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    }
                }
            } message: {
                Text("Enter a six-digit invite code")
            }
            .alert(errorText ?? "", isPresented: showingError) {
                Button("OK") { isLoading = false }
        }
    }
}

#Preview {
    CreateOrJoinView(isLoading: .constant(false))
}
