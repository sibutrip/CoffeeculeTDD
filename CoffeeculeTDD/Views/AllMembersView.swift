//
//  AllMembersView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/11/23.
//

import SwiftUI
import CloudKit

struct AllMembersView: View, ErrorAlertable {
    @State private var addingPerson = false
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    @State private var viewingHistory = false
    @State private var customizingCup = false
    @State private var selectingCoffeecule = false
    @State private var isRefreshing = false
    @Binding var someoneElseBuying: Bool
    @Binding var isBuying: Bool
    @Binding var columnCount: Int
    @State private var currentMagnification: CGFloat = 1
    @State private var zoomDirection: ZoomDirection?
    @State private var largeTextSize: CGSize = .zero
    @State private var refreshIconHeight: CGFloat = 0
    

    private var columns: [GridItem] {
        (0..<columnCount).map { _ in GridItem(.flexible(minimum: 10, maximum: .infinity),spacing: 0) }
    }
    
    var hasBuyer: Bool {
        coffeeculeManager.selectedBuyer != nil
    }
    
    var scaleAmount: CGFloat {
        guard let zoomDirection else { return 1 }
        return zoomDirection == .in ? 1.1 : 0.9
    }
    
    enum ZoomDirection {
        case `in`, out
    }
    
    @State private var refreshTask: Task<Void, Error>?
    
    @State var errorTitle: String?
    @State var errorMessage: String?
    @State var isLoading = false
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ScrollView {
                    GeometryReader { scrollViewGeo in
                        let viewYPosition = geo.frame(in: .named("refreshable")).minY
                        let scrollDragAmount = scrollViewGeo.frame(in: .named("refreshable")).minY
                        let refreshIconHeight = max(0, scrollDragAmount - viewYPosition)
                        LazyVGrid(columns: columns) {
                            ForEach($coffeeculeManager.usersInSelectedCoffeecule) { user in
                                let userValue = user.wrappedValue
                                Button {
                                    if coffeeculeManager.selectedUsers.contains(where: { $0 == userValue }) {
                                        coffeeculeManager.selectedUsers = coffeeculeManager.selectedUsers.filter { $0 != userValue }
                                    } else {
                                        coffeeculeManager.selectedUsers.append(userValue)
                                        coffeeculeManager.selectedUsers = coffeeculeManager.selectedUsers.sorted {
                                            $0.name < $1.name
                                        }
                                    }
                                    try? coffeeculeManager.createUserRelationships()
                                } label: {
                                    MemberView(with: user)
                                        .animation(.bouncy, value: scaleAmount)
                                        .scaleEffect(scaleAmount)
                                }
                            }
                        }
                        .preference(key: RefreshIconPreferenceKey.self, value: refreshIconHeight)
                    }
                    .frame(height: geo.size.width / CGFloat(columnCount) * CGFloat(coffeeculeManager.usersInSelectedCoffeecule.count) / CGFloat(columnCount) * 1.1)
                    .onPreferenceChange(RefreshIconPreferenceKey.self) { newValue in
                        refreshIconHeight = newValue
                        if refreshIconHeight > geo.size.height / 20 {
                            refresh()
                        }
                    }
                }
                .scrollDisabled(zoomDirection != nil)
                IsBuyingSheet(geo: geo, someoneElseBuying: $someoneElseBuying, isBuying: $isBuying)
                    .transition(.slide)
            }
            .if(true) { view in
                Group {
                    if #available(iOS 17, *) {
                        view
                            .highPriorityGesture(pinchToZoomGesture(view), including: hasBuyer ? .subviews : .all)
                    } else {
                        view
                    }
                }
            }
            .animation(.default, value: hasBuyer)
            .navigationTitle("Who's Here?")
            .background {
                VStack {
                    ChildSizeReader(size: $largeTextSize) {
                        Text("Who's Here?")
                            .font(.largeTitle)
                            .bold()
                    }
                    .frame(height: refreshIconHeight)
                    .frame(maxWidth: .infinity)
                    .opacity(0.0)
                    .overlay {
                        ZStack {
                            if refreshIconHeight < geo.size.height / 20 {
                                LottieView(animationName: "CheersSplash")
                            } else {
                                LottieViewAnimated(animationName: "CheersSplash")
                            }
                        }
                        .padding(.bottom, 3)
                        .frame(maxHeight: geo.size.height / 15)
                    }
                    Spacer()
                }
                .offset(y: !UIDevice.current.orientation.isLandscape ? -largeTextSize.height : 0)
            }
        }
        .animation(.default, value: columnCount)
        .toolbar {
            ToolbarItem {
                Button {
                    selectingCoffeecule = true
                } label: {
                    Label("Select Your Coffeecule", systemImage: "person.2.gobackward")
                }
            }
            ToolbarItem {
                Button {
                    customizingCup = true
                } label: {
                    Label("Customize Your Cup", systemImage: "cup.and.saucer")
                }
            }
            ToolbarItem {
                Button {
                    viewingHistory = true
                } label: {
                    Label("Transaction History", systemImage: "dollarsign.arrow.circlepath")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    addingPerson = true
                } label: {
                    Label("Add Person to Coffeecule", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $viewingHistory) {
            TransactionHistory()
        }
        .sheet(isPresented: $customizingCup) {
            CustomizeCupView()
        }
        .sheet(isPresented: $selectingCoffeecule) {
            SelectCoffeeculeSheet()
        }
        .sheet(isPresented: $addingPerson) {
            if let coffeecule = coffeeculeManager.selectedCoffeecule {
                AddPersonSheet(coffeecule: coffeecule)
                    .presentationDetents([.medium])
            }
        }
        .displaysAlertIfActionFails(for: self)
    }
    init(someoneElseBuying: Binding<Bool>, isBuying: Binding<Bool>, columnCount: Binding<Int>) {
        _someoneElseBuying = someoneElseBuying
        _isBuying = isBuying
        _columnCount = columnCount
    }
}

extension AllMembersView {
    func refresh() {
        if isLoading { return }
        displayAlertIfFailsAsync {
            try await coffeeculeManager.fetchUsersInCoffeecule()
            try await coffeeculeManager.fetchTransactionsInCoffeecule()
        }
    }
    
    @available(iOS 17, *)
    func pinchToZoomGesture<someView: View>(_ view: someView) -> some Gesture {
            MagnifyGesture()
                .onChanged { magnifyValue in
                    withAnimation {
                        if magnifyValue.magnification > currentMagnification {
                            zoomDirection = .in
                        } else {
                            zoomDirection = .out
                        }
                    }
                    currentMagnification = magnifyValue.magnification
                }
                .onEnded { magnifyValue in
                    if magnifyValue.magnification > 1 {
                        if columnCount > 1 {
                            columnCount -= 1
                        }
                    } else if columnCount < 4 {
                        columnCount += 1
                    }
                    withAnimation { zoomDirection = nil }
                    currentMagnification = 1
                }
    }
}

#Preview {
    AllMembersView(someoneElseBuying: .constant(false), isBuying: .constant(false), columnCount: .constant(2))
        .environmentObject(CoffeeculeManager<CloudKitService<CKContainer>>())
}

struct RefreshIconPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: Value = .zero
    
    static func reduce(value _: inout Value, nextValue: () -> Value) {
        _ = nextValue()
    }
}
