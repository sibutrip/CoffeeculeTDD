//
//  SelectCoffeeculeSheet.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/30/23.
//

import SwiftUI
import CloudKit

struct SelectCoffeeculeSheet: View {    
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    @State private var coffeeculeName = ""
    @State private var isCreatingCoffeecule = false
    
    @State private var inviteCode = ""
    @State private var isJoiningCoffeecule = false
    
    @Environment(\.dismiss) private var dismiss: DismissAction
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(coffeeculeManager.coffeecules) { coffeecule in
                        Button {
                            coffeeculeManager.selectedCoffeecule = coffeecule
                        } label: {
                            HStack {
                                if coffeeculeManager.selectedCoffeecule?.id == coffeecule.id {
                                    Image(systemName: "checkmark.circle")
                                } else {
                                    Image(systemName: "circle")
                                }
                                Text(coffeecule.name)
                            }
                        }
                    }
                    .foregroundStyle(Color.primary)
                }
                VStack {
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
                }
                .padding(.top, 5)
                .padding(.bottom, 40)
            }
            .toolbar {
                Button("Done") { dismiss() }
            }
            .navigationTitle("Select Your Coffeecule")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Create A Coffeecule", isPresented: $isCreatingCoffeecule) {
            VStack {
                TextField("Coffeecule Display Name", text: $coffeeculeName)
                HStack {
                    Button("Create") {
                        Task {
                            do {
                                try await coffeeculeManager.createCoffeecule(with: coffeeculeName)
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
    SelectCoffeeculeSheet()
}
