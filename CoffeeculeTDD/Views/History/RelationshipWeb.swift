////
////  RelationshipWeb.swift
////  Coffeecule
////
////  Created by Cory Tripathy on 9/14/23.
////
//
//import SwiftUI
//import Charts
//import CloudKit
//
//struct RelationshipWeb: View {
//    @State var chartScale: CGFloat = 0
//    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
//    var body: some View {
//        List {
//            Section("Tap members to view their relationship") {
//                ForEach($vm.relationships) { $relationship in
////                    let person = $relationship.wrappedValue.person
//                    Button {
//                        relationship.isPresent.toggle()
//                    } label: {
//                        RelationshipWebDetail(relationship: relationship)
//                    }
//                    .listRowSpacing(0)
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    RelationshipWeb(vm: ViewModel())
//}
