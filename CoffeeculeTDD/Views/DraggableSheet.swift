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
    
    @State private var opacityTimer: AnyCancellable?
    @State private var dragDistanceTimer: AnyCancellable?
    
    @State private var chartOpacity: CGFloat = 0
    private var sheetOpacity: Double { sheetAppears ? 1 : 0}
    
    private let transition = AnyTransition.move(edge: .bottom)
    
    @Binding var sheetAppears: Bool
    @Binding var contentIsShowing: Bool
    
    private func incrementOpacity(with action: @escaping (CGFloat, CGFloat) -> CGFloat) {
        opacityTimer?.cancel()
        opacityTimer = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let step: CGFloat = 0.05
                if self.chartOpacity >= 0 && self.chartOpacity <= 1 {
                    let newValue = action(self.chartOpacity, step)
                    let adjustedValue = max(min(1, newValue), 0)
                    self.chartOpacity = adjustedValue
                    if adjustedValue == 1 || adjustedValue == 0 {
                        opacityTimer?.cancel()
                    }
                }
            }
    }
    
    /// based on linear acceleration for first half and linear deceleration for the 2nd half
    ///
    /// using the formula for the area of a triangle:
    ///  A = bh/2 where
    ///      A = total distance to cover
    ///      b = total frames
    ///      h = 2A / b
    /// to do this, we divide the triangle into two regions:
    ///  first triangle (where 0 < b < totalFrames / 2
    ///  second triangle:
    ///      second full triangle is area from totalFrames / 2 -> total frames
    ///      second sub triangle is area from b -> total frames
    ///      second triangle area is full triangle minus second sub triangle
    /// then we add the two triangles together to get the total distance travelled
    /// so we add/subtract this value from the distance at the start
    private func incrementDragDistance(from startLocation: CGFloat, to endLocation: CGFloat, with action: @escaping (CGFloat, CGFloat) -> CGFloat) {
        let distanceToCover = abs(startLocation - endLocation)
        let startingDistance = self.dragDistance ?? 0
        let height = distanceToCover * 2 / 70
        dragDistanceTimer?.cancel()
        var framesRun = 0 // run 700 frames
        dragDistanceTimer = Timer.publish(every: 0.005, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                framesRun += 1
                let firstTriangleStep = min(35, framesRun)
                let secondTriangleStep = max(35, framesRun) - 35
                let firstTriangleBase = CGFloat(firstTriangleStep)
                let firstTriangleHeight = height * ( CGFloat(firstTriangleStep) / 35 )
                let firstTriangleArea = firstTriangleBase * firstTriangleHeight / 2
                var secondTriangleArea: CGFloat = 0
                if secondTriangleStep > 0 {
                    let secondSubTriangleBase = CGFloat(35 - secondTriangleStep)
                    let secondSubTriangleHeight = height * (CGFloat(35 - secondTriangleStep) / CGFloat(35))
                    let secondSubTriangleArea = secondSubTriangleBase * secondSubTriangleHeight / 2
                    let secondFullTriangleArea = (35 * height / 2)
                    secondTriangleArea = secondFullTriangleArea - secondSubTriangleArea
                }
                let currentDistance = firstTriangleArea + secondTriangleArea
                let smallestOfStartAndEndLocations = min(startLocation,endLocation)
                let largestOfStartAndEndLocations = max(startLocation, endLocation)
                let newValue = action(startingDistance, currentDistance)
                let adjustedValue = max(min((largestOfStartAndEndLocations), newValue), smallestOfStartAndEndLocations)
                self.dragDistance = adjustedValue
                if adjustedValue >= largestOfStartAndEndLocations || adjustedValue <= smallestOfStartAndEndLocations {
                    dragDistanceTimer?.cancel()
                }
            }
    }
    
    let header: () -> Header
    let content: () -> Content
    
    init(geo: GeometryProxy, sheetAppears: Binding<Bool>, contentIsShowing: Binding<Bool>, header: @escaping () -> Header, content: @escaping () -> Content) {
        self.geo = geo
        _sheetAppears = sheetAppears
        _contentIsShowing = contentIsShowing
        self.header = header
        self.content = content
    }
    
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
                                    let dragDistance = (dragDistance ?? 0)
                                    let newDistance = -newValue.translation.height + dragDistance
                                    if contentIsShowing {
                                        if newDistance < 0 {
                                            incrementDragDistance(from: dragDistance, to: 0, with: +)
                                            incrementOpacity(with: -)
                                            contentIsShowing = false
                                        } else if newDistance < (geo.size.height / 2) {
                                            incrementDragDistance(from: dragDistance, to: 0, with: -)
                                            incrementOpacity(with: -)
                                            contentIsShowing = false
                                        } else {
                                            incrementDragDistance(from: dragDistance, to: geo.size.height / 2, with: -)
                                        }
                                    } else {
                                        if newDistance > geo.size.height / 2 {
                                            incrementDragDistance(from: dragDistance, to: geo.size.height / 2, with: -)
                                            incrementOpacity(with: +)
                                            contentIsShowing = true
                                        } else if newDistance > 0 {
                                            incrementDragDistance(from: dragDistance, to: geo.size.height / 2, with: +)
                                            incrementOpacity(with: +)
                                            contentIsShowing = true
                                        } else {
                                            incrementDragDistance(from: dragDistance, to: 0, with: +)
                                            contentIsShowing = false
                                        }
                                    }
                                }
                        )
                        .onTapGesture {
                            let dragDistance = (dragDistance ?? 0)
                            if !contentIsShowing {
                                incrementOpacity(with: +)
                                incrementDragDistance(from: dragDistance, to: geo.size.height / 2, with: +)
                                contentIsShowing = true
                            } else {
                                incrementDragDistance(from: dragDistance, to: 0, with: -)
                                incrementOpacity(with: -)
                                contentIsShowing = false
                            }
                        }
                        .onAppear {
                            withAnimation(nil) {
                                chartOpacity = 0
                            }
                        }
                        .onDisappear {
                            dragDistance = 0
                            contentIsShowing = false
                        }
                        .transition(transition)
                }
            }
        }
        .opacity(sheetOpacity)
        .animation(.default, value: sheetAppears)
    }
}
