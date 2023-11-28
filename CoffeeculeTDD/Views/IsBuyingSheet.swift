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
    @Environment(\.editMode) var editMode
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    
    @State private var dragDistance: CGFloat? = nil
    @State private var buyButtonsSize: CGSize = .zero
    @State private var relationshipChartSize: CGSize = .zero
    
    @State private var timerCancellable: AnyCancellable?
    @State private var opacity: CGFloat = 0
    
    var hasBuyer: Bool {
        coffeeculeManager.selectedBuyer != nil
    }
        
    private func incrementOpacity(with action: @escaping (CGFloat, CGFloat) -> CGFloat) {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let step: CGFloat = 0.05
                if self.opacity >= 0 && self.opacity <= 1 {
                    let newValue = action(self.opacity, step)
                    let adjustedValue = max(min(1, newValue), 0)
                    self.opacity = adjustedValue
                    if adjustedValue == 1 || adjustedValue == 0 {
                        timerCancellable?.cancel()
                    }
                }
            }
    }
    
    var body: some View {
        if hasBuyer && !(editMode?.wrappedValue.isEditing ?? true) {
            let transition = AnyTransition.move(edge: .bottom)
            ChildSizeReader(size: $buyButtonsSize) {
                VStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: geo.size.width / 8, height: 8)
                        .foregroundStyle(.gray)
                        .padding(.top, 10)
                        .padding(.bottom, 5)
                    EqualWidthVStackLayout(spacing: 10) {
                        Button {
                            isBuying = true
                        } label: {
                            Text("\(coffeeculeManager.selectedBuyer?.name ?? "") is buying")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            someoneElseBuying = true
                        } label: {
                            Text("Someone else is buying")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(width: geo.size.width)
            }
            .padding(.bottom, 40 + (dragDistance ?? 0) )
            .overlay {
                VStack {
                    Spacer()
                    relationshipWebChart
                        .frame(height: max((dragDistance ?? 0), CGFloat(0)))
                        .opacity(opacity)
                }
            }
            .background(.regularMaterial)
            .transition(transition)
            .highPriorityGesture(
                DragGesture()
                    .onChanged { newValue in
                        let newDistance = -newValue.translation.height + (dragDistance ?? 0)
                        if newDistance < geo.size.height * 0.8 {
                            self.dragDistance = newDistance
                            opacity = min(max(0, newDistance - geo.size.height / 20) / (geo.size.height * 0.8 / 4), 1)
                        }
                    }
                    .onEnded { newValue in
                        withAnimation {
                            if (dragDistance ?? 0) + -newValue.predictedEndLocation.y > geo.size.height * (1/4) {
                                dragDistance = geo.size.height / 2
                                incrementOpacity(with: +)
                            } else {
                                dragDistance = 0
                                incrementOpacity(with: -)
                            }
                        }
                    }
            )
            .onTapGesture {
                withAnimation {
                    if (dragDistance ?? 0) == 0 {
                        dragDistance = geo.size.height / 2
                        incrementOpacity(with: +)
                    } else {
                        dragDistance = 0
                        incrementOpacity(with: -)
                    }
                }
            }
            .onDisappear {
                dragDistance = 0
            }
        }
    }
}


extension IsBuyingSheet {
    var relationshipWebChart: some View {
        chart(coffeeculeManager.selectedUserDebts)
            .animation(.default, value: coffeeculeManager.selectedUsers)
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
