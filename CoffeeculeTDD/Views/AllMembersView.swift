//
//  AllMembersView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/11/23.
//

import SwiftUI
import CloudKit

struct AllMembersView: View {
    @State var editMode: EditMode = .inactive
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    @State private var viewingHistory = false
    @State private var customizingCup = false
    @State private var isDeletingCoffeecule = false
    @State private var selectingCoffeecule = false
    @Binding var someoneElseBuying: Bool
    @Binding var isBuying: Bool
    @Binding var columnCount: Int
    @State private var currentMagnification: CGFloat = 1
    @State private var zoomDirection: ZoomDirection?
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
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
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
                                    .animation(.bouncy, value: scaleAmount)
                                    .scaleEffect(scaleAmount)
                            }
                            .disabled(editMode == .active)
                        }
                    }
                }
                IsBuyingSheet(geo: geo, someoneElseBuying: $someoneElseBuying, isBuying: $isBuying)
                if editMode == .active {
                    if let coffeecule = coffeeculeManager.selectedCoffeecule {
                        AddPersonSheet(geo: geo, coffeecule: coffeecule)
                    }
                }
            }
            .gesture(
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
            )
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
            CustomizeCupView()
        }
        .sheet(isPresented: $selectingCoffeecule) {
            SelectCoffeeculeSheet()
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
    init(someoneElseBuying: Binding<Bool>, isBuying: Binding<Bool>, columnCount: Binding<Int>) {
        _someoneElseBuying = someoneElseBuying
        _isBuying = isBuying
        _columnCount = columnCount
    }
}

#Preview {
    AllMembersView(someoneElseBuying: .constant(false), isBuying: .constant(false), columnCount: .constant(2))
        .environmentObject(CoffeeculeManager<CloudKitService<CKContainer>>())
}
