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
    let coffeecule: Coffeecule
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
    @State private var contentIsShowing = false
    @State private var textColor = Color.primary
    @State private var codeIsCopied = false
    var buttonTextColor: Color { colorScheme == .light ? .white : .primary }
    @State private var colorChange: AnyCancellable?
    @State private var linkCopied = ""
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
            VStack {
                Spacer()
                Spacer()
                Button {
                    linkCopied = coffeecule.inviteCode
                    codeIsCopied = true
                } label: {
                    ZStack {
                        if codeIsCopied {
                            Label("Copied!", systemImage: "list.bullet.clipboard")
                        }
                        Label("Copy Invite Code", systemImage: "rectangle.portrait.on.rectangle.portrait")
                            .opacity(codeIsCopied ? 0.0 : 1.0)
                            .foregroundStyle(buttonTextColor)
                    }
                    .font(.title2)
                    .padding(8)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(codeIsCopied ? Color.secondary : Color.accentColor)
                    }
                }
                Spacer()
                Text("OR")
                    .font(.title2)
                    .foregroundStyle(Color.secondary)
                Spacer()
                ShareLink(item: coffeecule.inviteCode, preview: SharePreview("Invite Code", image: "AppIcon")) {
                    Label("Share Invite Code", systemImage: "square.and.arrow.up")
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)
                Spacer()
                Spacer()
            }
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
        VStack {
            Spacer()
            AddPersonSheet(geo: geo, coffeecule: Coffeecule(with: "Test"))
        }
    }
}
