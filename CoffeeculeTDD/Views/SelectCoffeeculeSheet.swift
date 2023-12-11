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
    
    @State private var isLoading = false
    
    @Environment(\.dismiss) private var dismiss: DismissAction
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    List {
                        ForEach(coffeeculeManager.coffeecules) { coffeecule in
                            Button {
                                coffeeculeManager.selectedCoffeecule = coffeecule
                            } label: {
                                VStack {
                                    HStack {
                                        if coffeeculeManager.selectedCoffeecule?.id == coffeecule.id {
                                            Image(systemName: "checkmark.circle")
                                        } else {
                                            Image(systemName: "circle")
                                        }
                                        Text(coffeecule.name)
                                    }
                                    Text(coffeecule.inviteCode)
                                        .foregroundStyle(Color.secondary)
                                        .font(.caption)
                                }
                            }
                        }
                        .foregroundStyle(Color.primary)
                    }
                }
                VStack {
                    if isLoading {
                        LottieViewAnimated()
                    } else {
                        Spacer()
                    }
                    CreateOrJoinView(isLoading: $isLoading)
                        .padding(.top, 5)
                        .padding(.bottom, 40)
                }
            }
            .toolbar {
                Button("Done") { dismiss() }
            }
            .navigationTitle("Select Your Coffeecule")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SelectCoffeeculeSheet()
}
