//
//  OnboardingView.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 12/6/23.
//

import SwiftUI
import CloudKit

struct OnboardingView: View {
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    
    @State private var nameIsSubmitted = false
    @State private var displayName = ""
    
    @State private var isLoading = false

    var body: some View {
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
                                Task {
                                    try await coffeeculeManager.update(coffeeculeManager.user)
                                }
                            }
                            .submitLabel(.next)
                        Button {
                            coffeeculeManager.user?.name = displayName
                            nameIsSubmitted = true
                            Task {
                                try await coffeeculeManager.update(coffeeculeManager.user)
                            }
                        } label: {
                            Label("Submit", systemImage: "arrow.forward.circle")
                                .labelStyle(.iconOnly)
                        }
                    }
                    .padding()
                }
                .transition(.asymmetric(insertion: .identity, removal: .move(edge: .leading)))
            } else {
                CreateOrJoinView(isLoading: $isLoading)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .identity))
                    .overlay {
                        if isLoading {
                            LottieViewAnimated(animationName: "CheersSplash")
                        }
                    }
            }
        }
        .animation(.default, value: nameIsSubmitted)
        .onAppear {
            if coffeeculeManager.user?.name != "TEST" {
                nameIsSubmitted = true
            }
        }
    }
}

#Preview {
    OnboardingView()
}
