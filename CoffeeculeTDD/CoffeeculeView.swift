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
            } else {
                ForEach(coffeeculeManager.coffeecules) { coffeecule in
                    Text(coffeecule.id)
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
