//
//  CoffeeculeView.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/23/23.
//

import SwiftUI
import CloudKit

struct CoffeeculeView: View {
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
            if isFetchingCoffeecules {
                ProgressView()
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
                        try await coffeeculeManager.createCoffeecule()
                    } catch {
                        errorText = error.localizedDescription
                    }
                }
            }
        }
        .onAppear {
            Task {
                do {
                    try await coffeeculeManager.fetchCoffeecules()
                    coffeeculeManager.selectedCoffeecule = coffeeculeManager.coffeecules.first
                } catch {
                    errorText = error.localizedDescription
                }
                isFetchingCoffeecules = false
            }
        }
    }
}

#Preview {
    CoffeeculeView()
}
