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
    var body: some View {
        Picker("Select A Coffeecule", selection: $coffeeculeManager.selectedCoffeecule) {
            ForEach(coffeeculeManager.coffeecules) { coffeecule in
                Text(coffeecule.id).tag(Optional(coffeecule))
            }
        }
    }
}

#Preview {
    SelectCoffeeculeSheet()
}
