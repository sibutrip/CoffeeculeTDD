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
    @State var errorText: String?
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
            ForEach(coffeeculeManager.coffeecules) { coffeecule in
                Text(coffeecule.id)
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
    }
}

#Preview {
    CoffeeculeView()
}
