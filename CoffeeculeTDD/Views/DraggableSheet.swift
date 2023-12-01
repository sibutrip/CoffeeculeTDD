//
//  DraggableSheet.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/28/23.
//

import SwiftUI
import CloudKit
import Combine
import Charts

struct DraggableSheet<Header: View, Content: View>: View {
    let geo: GeometryProxy
    @Environment(\.editMode) var editMode
    
    @State private var dragDistance: CGFloat? = nil
    
    @State private var timerCancellable: AnyCancellable?
    @State private var chartOpacity: CGFloat = 0
    @State private var sheetOpacity: Double = 1
    
    private let transition = AnyTransition.move(edge: .bottom)
    
    @Binding var sheetAppears: Bool
    
    private func incrementOpacity(with action: @escaping (CGFloat, CGFloat) -> CGFloat) {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let step: CGFloat = 0.05
                if self.chartOpacity >= 0 && self.chartOpacity <= 1 {
                    let newValue = action(self.chartOpacity, step)
                    let adjustedValue = max(min(1, newValue), 0)
                    self.chartOpacity = adjustedValue
                    if adjustedValue == 1 || adjustedValue == 0 {
                        timerCancellable?.cancel()
                    }
                }
            }
    }
    
    let header: () -> Header
    let content: () -> Content
    
    var body: some View {
        Group {
            if sheetAppears {
                Group {
                    header()
                        .frame(width: geo.size.width)
                        .padding(.bottom, 40 + (dragDistance ?? 0) )
                        .overlay {
                            VStack {
                                Spacer()
                                content()
                                    .frame(height: max((dragDistance ?? 0), CGFloat(0)))
                                    .opacity(chartOpacity)
                            }
                        }
                        .background(.regularMaterial)
                        .highPriorityGesture(
                            DragGesture()
                                .onChanged { newValue in
                                    let newDistance = -newValue.translation.height + (dragDistance ?? 0)
                                    if newDistance < geo.size.height * 0.8 {
                                        self.dragDistance = newDistance
                                        chartOpacity = min(max(0, newDistance - geo.size.height / 20) / (geo.size.height * 0.8 / 4), 1)
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
                        .onAppear {
                            withAnimation(nil) {
                                chartOpacity = 0
                                sheetOpacity = 1
                            }
                        }
                        .onDisappear {
                            dragDistance = 0
                        }
                        .transition(transition)
                }
            }
        }
        .onChangeiOS17Compatible(of: sheetAppears, perform: { isAppearing in
            let animation = isAppearing ? Animation.default : Animation.default.delay(0.2)
            withAnimation(animation) {
                sheetOpacity = isAppearing ? 1 : 0
            }
        })
        .opacity(sheetOpacity)
        .animation(.default, value: sheetAppears)
    }
}

#Preview {
    GeometryReader { geo in
        IsBuyingSheet(geo: geo, someoneElseBuying: .constant(false), isBuying: .constant(false))
    }
}
