//
//  AddPersonSheet.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 12/1/23.
//

import SwiftUI
import CloudKit
import Combine

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
    @State private var colorChange: AnyCancellable?
    var body: some View {
        DraggableSheet(geo: geo, sheetAppears: .constant(true), contentIsShowing: $contentIsShowing) {
            EqualWidthVStackLayout(spacing: 10) {
                HStack {
                    if !contentIsShowing {
                        Label("Add New Person", systemImage: "person.crop.circle.fill.badge.plus")
                            .labelStyle(.iconOnly)
                            .transition(.asymmetric(insertion: .scale.combined(with: .move(edge: .bottom)), removal: .identity))
                    }
                    Label("Add New Person", systemImage: "person.crop.circle.fill.badge.plus")
                        .labelStyle(.titleOnly)
                }
                .animation(.default, value: contentIsShowing)
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
            textColor = contentIsShowing ? Color.primary : (colorScheme == .light ? Color.white : Color.black)
        }
    }
}

#Preview {
    GeometryReader { geo in
        AddPersonSheet(geo: geo)
    }
}
