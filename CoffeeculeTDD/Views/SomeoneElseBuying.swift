//
//  SomeoneElseBuying.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/11/23.
//

import SwiftUI
import CloudKit

struct SomeoneElseBuying: View {
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    @Binding var someoneElseBuying: Bool
    @Binding var isBuying: Bool
    @Binding var columnCount: Int
    private var columns: [GridItem] {
        (0..<columnCount).map { _ in GridItem(.flexible(minimum: 10, maximum: .infinity),spacing: 0) }
    }
    var hasBuyer: Bool {
        coffeeculeManager.selectedBuyer != nil
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach($coffeeculeManager.selectedUsers) { user in
                            Button {
                                coffeeculeManager.selectedBuyer = user.wrappedValue
                            } label: {
                                MemberView(with: user, someoneElseBuying: true)
                            }
                        }
                    }
                }
//                .toolbar {
//                    ToolbarItem(placement: .topBarLeading) {
//                        Button("Cancel") {
//                            someoneElseBuying = false
//                        }
//                    }
//                }
                if let selectedBuyer = coffeeculeManager.selectedBuyer {
                    let transition = AnyTransition.move(edge: .bottom)
                    EqualWidthVStackLayout(spacing: 10) {
                        Button {
                            isBuying = true
                        } label: {
                            Text("\(selectedBuyer.name) is buying")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        Button {
                            someoneElseBuying = false
                        } label: {
                            Text("Cancel")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .padding(.bottom, 30)
                    .background(.regularMaterial)
                    .transition(transition)
                }
            }
            .animation(.default, value: hasBuyer)
            .navigationTitle(someoneElseBuying ? "Who's Buying?" : "Who's Here?")
        }
    }
}

#Preview {
    SomeoneElseBuying(someoneElseBuying: .constant(true), isBuying: .constant(true), columnCount: .constant(2))
}
