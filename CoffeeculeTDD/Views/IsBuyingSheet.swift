//
//  IsBuyingSheet.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/28/23.
//

import SwiftUI
import CloudKit
import Combine
import Charts

struct IsBuyingSheet: View {
    let geo: GeometryProxy
    @Binding var someoneElseBuying: Bool
    @Binding var isBuying: Bool
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    
    @State private var dragDistance: CGFloat? = nil
    @State private var buyButtonsSize: CGSize = .zero
    @State private var relationshipChartSize: CGSize = .zero
    @State private var contentIsShowing = false
    
    @State private var timerCancellable: AnyCancellable?
    @State private var chartOpacity: CGFloat = 0
    @State private var sheetOpacity: Double = 1
    
    var hasBuyer: Bool {
        coffeeculeManager.selectedBuyer != nil
    }
    
    var isShowingSheet: Binding<Bool> {
        Binding {
            hasBuyer
        } set: { _ in }
    }
    
    var body: some View {
        DraggableSheet(geo: geo, sheetAppears: isShowingSheet, contentIsShowing: $contentIsShowing) {
            VStack {
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: geo.size.width / 8, height: 8)
                    .foregroundStyle(.gray)
                    .padding(.top, 10)
                if contentIsShowing {
                    Text("Current Debts")
                        .bold()
                        .transition(.asymmetric(insertion: .opacity, removal: .identity))
                    
                } else {
                    VStack {
                        EqualWidthVStackLayout(spacing: 10) {
                            Button {
                                isBuying = true
                            } label: {
                                VStack {
                                    HStack(spacing: 0) {
                                        Text(coffeeculeManager.selectedBuyer?.name ?? "")
                                            .lineLimit(1)
                                        Text(" is Buying")
                                    }
                                        .font(.title2)
                                        .frame(maxWidth: .infinity)
                                    Text("It's their turn")
                                }
                                .frame(maxWidth: geo.size.width * 0.8)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button {
                                someoneElseBuying = true
                            } label: {
                                Text("Someone else is buying")
                                    .font(.title2)
                                    .frame(maxWidth: .infinity)
                                    .frame(maxWidth: geo.size.width * 0.8)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 5)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                    .transition(.asymmetric(insertion: .opacity, removal: .identity))
                }
            }
            .animation(.default, value: contentIsShowing)
        } content: {
            relationshipWebChart
        }
        .animation(.default, value: contentIsShowing)
    }
}

extension IsBuyingSheet {
    var relationshipWebChart: some View {
        chart(coffeeculeManager.selectedUserDebts)
            .animation(.default, value: coffeeculeManager.selectedUsers)
            .overlay {
                let totalNumberOfDebts = coffeeculeManager.selectedUserDebts.reduce(0) { partialResult, debts in
                    partialResult + abs(debts.value)
                }
                if totalNumberOfDebts == 0 {
                    Text("No debts to display")
                }
            }
    }
    
    private func chart(_ debt: [User : Int])  -> some View {
        let displayedDebts = debt
        if #available(iOS 16, *) {
            return Chart(displayedDebts.keys.sorted(by: { $0.name < $1.name }), id: \.self) {
                BarMark(
                    x: .value("person", $0.name),
                    y: .value("cups bought", displayedDebts[$0] ?? 10)
                )
                .foregroundStyle(displayedDebts[$0] ?? 0 > 0 ? .blue : .red)
            }
            .padding(.horizontal)
            .padding(.vertical)
        } else {
            return EmptyView()
        }
    }
}


#Preview {
    GeometryReader { geo in
        IsBuyingSheet(geo: geo, someoneElseBuying: .constant(false), isBuying: .constant(false))
    }
}
