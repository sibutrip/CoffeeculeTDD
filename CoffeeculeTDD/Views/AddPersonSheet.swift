//
//  AddPersonSheet.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 12/1/23.
//

import SwiftUI
import CloudKit

struct AddPersonSheet: View {
    let geo: GeometryProxy
    @Environment(\.editMode) var editMode
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    private let transition = AnyTransition.move(edge: .bottom)
    @State private var addingPerson = false
    private var showingSheet: Binding<Bool> {
        Binding {
            editMode?.wrappedValue.isEditing == true
        } set: { _ in }
    }
//    @State var sheetSize: CGSize = .zero
    @State var personShowing = true
//    var sheetIsExpanded: Bool { sheetSize.height > geo.size.height / 4 }
    var body: some View {
//        ChildSizeReader(size: $sheetSize) {
            DraggableSheet(geo: geo, sheetAppears: $personShowing) {
                EqualWidthVStackLayout(spacing: 10) {
                    Label("Add New Person", systemImage: "person.crop.circle.fill.badge.plus")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .background {
                            Group {
//                                if sheetIsExpanded { EmptyView() }
//                                else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundStyle(Color.accentColor)
//                                }
                            }
                        }
                }
                .padding(.vertical)
            } content: {
                Text(coffeeculeManager.selectedCoffeecule?.name ?? "")
            }
//        }
//        .animation(nil, value: sheetIsExpanded)
    }
}

#Preview {
    GeometryReader { geo in
        AddPersonSheet(geo: geo)
    }
}
