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
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    private let transition = AnyTransition.move(edge: .bottom)
    @State private var addingPerson = false
    private var showingSheet: Binding<Bool> {
        Binding {
            editMode?.wrappedValue.isEditing == true
        } set: { _ in }
    }
    @State var contentIsShowing = false
    @State var textColor = Color.primary
    var body: some View {
        DraggableSheet(geo: geo, sheetAppears: .constant(true), contentIsShowing: $contentIsShowing) {
            EqualWidthVStackLayout(spacing: 10) {
                Label("Add New Person", systemImage: "person.crop.circle.fill.badge.plus")
                    .font(.title2)
                    .padding(6)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(textColor)
                    .background {
                        Group {
                            if contentIsShowing { EmptyView() }
                            else {
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
            }
            .padding(.vertical)
        } content: {
            Text(coffeeculeManager.selectedCoffeecule?.name ?? "")
        }
        .onAppear {
            self.textColor = colorScheme == .light ? Color.white : Color.black
        }
        .onChangeiOS17Compatible(of: contentIsShowing) { contentIsShowing in
            if !contentIsShowing {
                DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(300))) {
                    self.textColor = colorScheme == .light ? Color.white : Color.black
                }
            } else {
                self.textColor = Color.primary
            }
        }
    }
}

#Preview {
    GeometryReader { geo in
        AddPersonSheet(geo: geo)
    }
}
