////
////  HistoryView.swift
////  Coffeecule
////
////  Created by Cory Tripathy on 9/14/23.
////
//
//import SwiftUI
//import CloudKit
//
//struct HistoryView: View {
//    enum HistoryType: String {
//        case Transactions, Relationships
//    }
//    @State var historyType: HistoryType = .Transactions
//    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
//    var body: some View {
//        NavigationStack {
//            VStack {
//                Picker("History", selection: $historyType) {
//                    Text("Transactions").tag(HistoryType.Transactions)
//                    Text("Relationships").tag(HistoryType.Relationships)
//                }
//                .pickerStyle(.segmented)
//                .padding(.horizontal)
//                Spacer()
//                switch historyType {
//                case .Transactions:
//                    TransactionHistory()
//                case .Relationships:
//                    RelationshipWeb()
//                }
//            }
//            .navigationTitle(historyType.rawValue)
//            .navigationBarTitleDisplayMode(.inline)
//        }
//    }
//}
//
//#Preview {
//    HistoryView()
//        .environmentObject(CoffeeculeManager<CloudKitService<CKContainer>>())
//}
