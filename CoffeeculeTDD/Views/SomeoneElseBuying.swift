////
////  SomeoneElseBuying.swift
////  Coffeecule
////
////  Created by Cory Tripathy on 9/11/23.
////
//
//import SwiftUI
//import CloudKit
//
//struct SomeoneElseBuying: View {
//    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
//    @Binding var someoneElseBuying: Bool
//    @Binding var isBuying: Bool
//    private let columns = [
//        GridItem(.flexible(minimum: 10, maximum: .infinity)),
//        GridItem(.flexible(minimum: 10, maximum: .infinity))
//    ]
//    var hasBuyer: Bool {
//        vm.currentBuyer != Person()
//    }
//    
//    var body: some View {
//        GeometryReader { geo in
//            VStack(spacing: 0) {
//                ScrollView {
//                    LazyVGrid(columns: columns) {
//                        ForEach($vm.relationships) { relationship in
//                            if relationship.wrappedValue.isPresent {
//                                Button {
//                                    vm.currentBuyer = relationship.wrappedValue.person
//                                } label: {
//                                    MemberView(relationship: relationship, someoneElseBuying: true)
//                                }
//                            }
//                        }
//                    }
//                }
////                .toolbar {
////                    ToolbarItem(placement: .topBarLeading) {
////                        Button("Cancel") {
////                            someoneElseBuying = false
////                        }
////                    }
////                }
//                if hasBuyer {
//                    let transition = AnyTransition.move(edge: .bottom)
//                    EqualWidthVStackLayout(spacing: 10) {
//                        Button {
//                            isBuying = true
//                        } label: {
//                            Text("\(vm.currentBuyer.name) is buying")
//                                .font(.title2)
//                                .frame(maxWidth: .infinity)
//                        }
//                        .buttonStyle(.borderedProminent)
//                        Button {
//                            someoneElseBuying = false
//                        } label: {
//                            Text("Cancel")
//                                .font(.title2)
//                                .frame(maxWidth: .infinity)
//                        }
//                        .buttonStyle(.bordered)
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .padding(.bottom, 30)
//                    .background(.regularMaterial)
//                    .transition(transition)
//                }
//            }
//            .animation(.default, value: hasBuyer)
//            .navigationTitle(someoneElseBuying ? "Who's Buying?" : "Who's Here?")
//        }
//    }
//}
//
//#Preview {
//    SomeoneElseBuying(vm: ViewModel(), someoneElseBuying: .constant(true), isBuying: .constant(false))
//}
