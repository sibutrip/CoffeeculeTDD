//
//  CoffeeculeView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/7/23.
//

import CloudKit
import SwiftUI

struct CoffeeculeView: View, ErrorAlertable {
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    @State var someoneElseBuying = false
    @State var isBuying = false
    @State var isDeletingCoffeecule = false
    @AppStorage("Column Count") var columnCount = 2
    @State var processingTransaction = false
    
    @State var errorTitle: String?
    @State var errorMessage: String?
    @State var isLoading = false
    
    @State var noCoffeecules = false
    var hasBuyer: Bool {
        coffeeculeManager.selectedBuyer != nil
    }
    var body: some View {
        NavigationStack {
            Group {
                if noCoffeecules {
                    OnboardingView()
                } else {
                    if !someoneElseBuying {
                        AllMembersView(someoneElseBuying: $someoneElseBuying, isBuying: $isBuying, columnCount: $columnCount)
                    } else {
                        SomeoneElseBuying(someoneElseBuying: $someoneElseBuying, isBuying: $isBuying, columnCount: $columnCount)
                    }
                }
            }
            .overlay {
                if processingTransaction {
                    LottieViewAnimated(animationName: "CheersTransaction", loopMode: .playOnce, isShowing: $processingTransaction)
                }
            }
        }
        .onChangeiOS17Compatible(of: coffeeculeManager.selectedCoffeecule) { newValue in
            displayAlertIfFailsAsync {
                coffeeculeManager.usersInSelectedCoffeecule = []
                try await coffeeculeManager.fetchUsersInCoffeecule()
                try await coffeeculeManager.fetchTransactionsInCoffeecule()
                try coffeeculeManager.createUserRelationships()
            }
        }
        .onAppear {
            if coffeeculeManager.coffeecules.isEmpty {
                noCoffeecules = true
            } else {
                noCoffeecules = false
            }
        }
        .onChangeiOS17Compatible(of: coffeeculeManager.coffeecules) { newValue in
            if !newValue.isEmpty { noCoffeecules = false }
        }
        .alert("Is \(coffeeculeManager.selectedBuyer?.name ?? "") buying coffee?", isPresented: $isBuying) {
            HStack {
                Button("Yes") {
                    processingTransaction = true
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
        .displaysAlertIfActionFails(for: self)
        .animation(.default, value: someoneElseBuying)
    }
}
