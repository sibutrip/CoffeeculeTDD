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
    @Environment(\.dismiss) private var dismiss: DismissAction
    var body: some View {
        NavigationStack {
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
                Button {
                    isCreatingCoffeecule = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Create A Coffeecule")
                        Spacer()
                    }
                }
            }
            .toolbar {
                Button("Done") { dismiss() }
            }
            .navigationTitle("Select Your Coffeecule")
            .navigationBarTitleDisplayMode(.inline)
        }
        //        VStack {
        //            Picker("Select A Coffeecule", selection: $coffeeculeManager.selectedCoffeecule) {
        //                ForEach(coffeeculeManager.coffeecules) { coffeecule in
        //                    Text(coffeecule.name).tag(Optional(coffeecule))
        //                }
        //            }
        //        }
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
    }
}

#Preview {
    SelectCoffeeculeSheet()
}
