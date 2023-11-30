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
    var body: some View {
        VStack {
            Picker("Select A Coffeecule", selection: $coffeeculeManager.selectedCoffeecule) {
                ForEach(coffeeculeManager.coffeecules) { coffeecule in
                    Text(coffeecule.name).tag(Optional(coffeecule))
                }
            }
            Button("Create Coffeecule") {
                isCreatingCoffeecule = true
            }
        }
        .alert("Create a coffeecule", isPresented: $isCreatingCoffeecule) {
            VStack {
                TextField("Name", text: $coffeeculeName)
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
    }
}

#Preview {
    SelectCoffeeculeSheet()
}
