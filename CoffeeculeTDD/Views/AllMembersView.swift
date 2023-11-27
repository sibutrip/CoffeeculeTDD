//
//  AllMembersView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/11/23.
//

import SwiftUI
import CloudKit
import Charts
import Combine

struct AllMembersView: View {
    @State var share: CKShare?
    @State var container: CKContainer?
    @Environment(\.editMode) var editMode
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    @State private var userIsOwner = false
    @State private var viewingHistory = false
    @State private var customizingCup = false
    @State private var isDeletingCoffeecule = false
    @State private var isSharing = false
    @Binding var someoneElseBuying: Bool
    @Binding var isBuying: Bool
    
    @State var dragDistance: CGFloat? = nil
    @State private var buyButtonsSize: CGSize = .zero
    @State private var relationshipChartSize: CGSize = .zero
    
    private let columns = [
        GridItem(.flexible(minimum: 10, maximum: .infinity),spacing: 0),
        GridItem(.flexible(minimum: 10, maximum: .infinity),spacing: 0)
    ]
    var hasBuyer: Bool {
        coffeeculeManager.selectedBuyer != nil
    }
    
    @State private var timerCancellable: AnyCancellable?
    @State var opacity: CGFloat = 0
    
    private func lowerOpacity() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let step: Double = 0.025
                if self.opacity > 0.0 {
                    self.opacity -= step
                } else {
                    timerCancellable?.cancel()
                }
            }
    }
    
    private func raiseOpacity() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let step: Double = 0.025
                if self.opacity < 1.0 {
                    self.opacity += step
                } else {
                    timerCancellable?.cancel()
                }
            }
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Picker("Select A Coffeecule", selection: $coffeeculeManager.selectedCoffeecule) {
                    ForEach(coffeeculeManager.coffeecules) { coffeecule in
                        Text(coffeecule.id).tag(Optional(coffeecule))
                    }
                }
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach($coffeeculeManager.usersInSelectedCoffeecule) { user in
                            let userValue = user.wrappedValue
                            Button {
                                if coffeeculeManager.selectedUsers.contains(where: { $0 == userValue }) {
                                    coffeeculeManager.selectedUsers = coffeeculeManager.selectedUsers.filter { $0 != userValue }
                                } else {
                                    coffeeculeManager.selectedUsers.append(userValue)
                                }
                                try? coffeeculeManager.createUserRelationships()
                            } label: {
                                MemberView(with: user)
                            }
                            .disabled(editMode?.wrappedValue.isEditing ?? false)
                        }
                    }
                }
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
                                    opacity = max(0, newDistance - geo.size.height / 20) / (geo.size.height * 0.8 / 4)
                                }
                            }
                            .onEnded { newValue in
                                withAnimation {
                                    if (dragDistance ?? 0) + -newValue.predictedEndLocation.y > geo.size.height * (1/4) {
                                        dragDistance = geo.size.height / 2
                                        raiseOpacity()
                                    } else {
                                        dragDistance = 0
                                        lowerOpacity()
                                    }
                                }
                            }
                    )
                    .onTapGesture {
                        withAnimation {
                            if dragDistance == 0 {
                                dragDistance = geo.size.height / 2
                                raiseOpacity()
                            } else {
                                dragDistance = 0
                                lowerOpacity()
                            }
                        }
                    }
                    .onDisappear {
                        dragDistance = 0
                    }
                }
                if editMode?.wrappedValue.isEditing ?? false {
                    let transition = AnyTransition.move(edge: .bottom)
                    EqualWidthVStackLayout(spacing: 10) {
                        Button {
                            //                            Task {
                            //                                try await vm.shareCoffeecule()
                            //                                if let share = await vm.repository.rootShare {
                            //                                    self.share = share
                            //                                    self.container = Repository.container
                            //                                    isSharing = true
                            //                                }
                            //                            }
                        } label: {
                            Label("Add New Person", systemImage: "person.crop.circle.fill.badge.plus")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        if userIsOwner {
                            Button {
                                isDeletingCoffeecule = true
                            } label: {
                                Label("Delete Coffeecule", systemImage: "trash")
                                    .font(.title2)
                                    .frame(maxWidth: .infinity)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .padding(.bottom, 30)
                    .frame(width: geo.size.width)
                    .background(.regularMaterial)
                    .transition(transition)
                }
            }
            .animation(.default, value: hasBuyer)
            .navigationTitle("Who's Here?")
        }
        .toolbar {
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
                EditButton()
            }
        }
        .sheet(isPresented: $viewingHistory) {
            //            TransactionHistory(vm: vm)
        }
        .sheet(isPresented: $customizingCup) {
            //            CustomizeCupView(vm: vm)
        }
        .alert("Are you sure you want to delete your Coffeecule? This action is not reversable.", isPresented: $isDeletingCoffeecule) {
            HStack {
                Button("Yes", role: .destructive) {
                    //                    Task {
                    //                        do {
                    //                            try await vm.deleteCoffeecule()
                    //                        } catch {
                    //                            print(error.localizedDescription)
                    //                        }
                    //                    }
                }
                Button("No", role: .cancel) {
                    isDeletingCoffeecule = false
                }
                
            }
        }
    }
    init(someoneElseBuying: Binding<Bool>, isBuying: Binding<Bool>) {
        _someoneElseBuying = someoneElseBuying
        _isBuying = isBuying
    }
}

#Preview {
    AllMembersView(someoneElseBuying: .constant(false), isBuying: .constant(false))
        .environmentObject(CoffeeculeManager<CloudKitService<CKContainer>>())
}

extension AllMembersView {
    var relationshipWebChart: some View {
        //        Section {
        chart(coffeeculeManager.selectedUserDebts)
        //                .frame(height: 100)
            .animation(.default, value: coffeeculeManager.selectedUsers)
        //                .onAppear { withAnimation { chartScale = 1 } }
        //                .onDisappear { withAnimation { chartScale = 0 } }
        //        }
    }
    func chart(_ debt: [User : Int])  -> some View {
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
