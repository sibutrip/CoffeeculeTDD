//
//  HistoryView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 8/24/23.
//

import CloudKit
import SwiftUI

struct TransactionHistory: View, ErrorAlertable {
    
    @State var isLoading = true
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    @State var datesAndTransactions: [Date: [Transaction]] = [:]
    @State var errorTitle: String?
    @State var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    LottieViewAnimated(animationName: "CheersSplash")
                } else {
                    VStack(spacing: 0) {
                        if datesAndTransactions.isEmpty {
                            Text("No previous transactions. Try to buy a coffee first!")
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .ignoresSafeArea()
                                .background {
                                    Color("ListBackground")
                                }
                        } else {
                            List {
                                ForEach(datesAndTransactions.keys.sorted(by: { $0 > $1 }), id: \.self) { date in
                                    let unsortedTransactions = datesAndTransactions[date] ?? []
                                    let transactions = unsortedTransactions.sorted(by: { first, second in
                                        first.thirdParent?.name ?? "" < second.thirdParent?.name ?? ""
                                    })
                                    if !transactions.isEmpty {
                                        Section(date.formatted(date: .abbreviated, time: .omitted)) {
                                            ForEach(transactions) { transaction in
                                                TransactionHistoryDetail(transaction: transaction)
                                                    .listRowSpacing(0)
                                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                        Button {
                                                            withAnimation {
                                                                datesAndTransactions[date] = datesAndTransactions[date]?
                                                                    .filter { $0.id != transaction.id }
                                                            }
                                                            Task {
                                                                try await coffeeculeManager.remove(transaction)
                                                            }
                                                        } label: {
                                                            Label("Trash", systemImage: "trash")
                                                        }
                                                        .tint(.red)
                                                    }
                                            }
                                        }
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .refreshable {
                                //                                Task {
                                //                                    await vm.refreshData()
                                //                                    let transactions = await vm.repository.transactions?.sorted { $0.creationDate! > $1.roundedDate! } ?? []
                                //                                    let datesAndTransactions = Dictionary(grouping: transactions) { $0.roundedDate! }
                                //                                    self.datesAndTransactions = datesAndTransactions
                                //                                    //            transactions.forEach { print($0.buyerName) }
                                //                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Transaction History")
            .navigationBarTitleDisplayMode(.inline)
        }
        .displaysAlertIfActionFails(for: self)
        .task {
            isLoading = true
            let transactions = coffeeculeManager.transactionsInSelectedCoffeecule.sorted { first, second in
                first.creationDate ?? Date() > second.roundedDate ?? Date()
            }
            let datesAndTransactions = Dictionary(grouping: transactions) { $0.roundedDate ?? Calendar.autoupdatingCurrent.dateComponents([.calendar,.day,.month,.year], from: Date()).date! }
            self.datesAndTransactions = datesAndTransactions
            //            transactions.forEach { print($0.buyerName) }
            isLoading = false
        }
    }
}

#Preview {
    TransactionHistory()
}
