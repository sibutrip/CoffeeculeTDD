//
//  AllMembersView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/11/23.
//

import SwiftUI
import CloudKit

struct AllMembersView: View {
//    @State var share: CKShare?
//    @State var container: CKContainer?
    @State var editMode: EditMode = .inactive
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
//    @State private var userIsOwner = false
    @State private var viewingHistory = false
    @State private var customizingCup = false
    @State private var isDeletingCoffeecule = false
//    @State private var isSharing = false
    @State private var selectingCoffeecule = false
    @Binding var someoneElseBuying: Bool
    @Binding var isBuying: Bool
//    @State private var isToggled = false
    
    private let columns = [
        GridItem(.flexible(minimum: 10, maximum: .infinity),spacing: 0),
        GridItem(.flexible(minimum: 10, maximum: .infinity),spacing: 0)
    ]
    var hasBuyer: Bool {
        coffeeculeManager.selectedBuyer != nil
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
                            .disabled(editMode == .active)
                        }
                    }
                }
                IsBuyingSheet(geo: geo, someoneElseBuying: $someoneElseBuying, isBuying: $isBuying)
                if editMode == .active {
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
//                        if userIsOwner {
//                            Button {
//                                isDeletingCoffeecule = true
//                            } label: {
//                                Label("Delete Coffeecule", systemImage: "trash")
//                                    .font(.title2)
//                                    .frame(maxWidth: .infinity)
//                                    .foregroundStyle(.red)
//                            }
//                            .buttonStyle(.bordered)
//                        }
                    }
                    .padding()
//                    .padding(.bottom, 30)
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
                    selectingCoffeecule = true
                } label: {
                    Label("Select Your Coffeecule", systemImage: "arrow.triangle.2.circlepath.circle")
                }
            }
            ToolbarItem {
                Button {
                    customizingCup = true
                } label: {
                    Label("Customize Your Cup", systemImage: "cup.and.saucer")
                }
            }
            if coffeeculeManager.coffeecules.count > 1 {
                ToolbarItem {
                    Button {
                        viewingHistory = true
                    } label: {
                        Label("Transaction History", systemImage: "dollarsign.arrow.circlepath")
                    }
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $viewingHistory) {
            TransactionHistory()
        }
        .sheet(isPresented: $customizingCup) {
            CustomizeCupView(user: $coffeeculeManager.user)
        }
        .sheet(isPresented: $selectingCoffeecule) {
            
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
        .environment(\.editMode, $editMode)
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
