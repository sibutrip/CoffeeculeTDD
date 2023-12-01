//
//  AddPersonSheet.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 12/1/23.
//

import SwiftUI

struct AddPersonSheet: View {
    let geo: GeometryProxy
    private let transition = AnyTransition.move(edge: .bottom)
    @State private var addingPerson = false
    var body: some View {
        Group {
            if !addingPerson {
                EqualWidthVStackLayout(spacing: 10) {
                    Button {
                        withAnimation {
                            addingPerson = true
                        }
                    } label: {
                        Label("Add New Person", systemImage: "person.crop.circle.fill.badge.plus")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            } else {
                VStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: geo.size.width / 8, height: 8)
                        .foregroundStyle(.gray)
                        .padding(.top, 10)
                        .padding(.bottom, 5)
                    Text("Wooo")
                }
            }
        }
        .frame(width: geo.size.width)
        .padding(.bottom, addingPerson ? geo.size.height / 2 : 0)
        .background(.regularMaterial)
        .transition(transition)
    }
}

#Preview {
    GeometryReader { geo in
        AddPersonSheet(geo: geo)
    }
}
