//
//  CustomizeCupView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/8/23.
//

import SwiftUI
import CloudKit

struct CustomizeCupView: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var coffeeculeManager: CoffeeculeManager<CloudKitService<CKContainer>>
    @State var userNotFound = false
    
    var displayName: Binding<String> {
        Binding {
            coffeeculeManager.user?.name ?? ""
        } set: { newName in
            coffeeculeManager.user?.name = newName
        }
    }
    
    let columns = [
        GridItem(.flexible(minimum: 10, maximum: .infinity)),
        GridItem(.flexible(minimum: 10, maximum: .infinity))
    ]
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Spacer()
                TextField("Display Name:", text: displayName)
                Spacer()
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(MugIcon.allCases,id: \.rawValue) { mugIcon in
                        Button {
                            coffeeculeManager.user?.mugIconString = mugIcon.rawValue
                        } label: {
                            CupPickerDetail(icon: mugIcon)
                        }
                    }
                }
                Spacer()
                HStack {
                    ForEach(UserColor.allCases,id: \.rawValue) { color in
                        Button {
                            coffeeculeManager.user?.userColorString = color.rawValue
                        } label: {
                            ColorPickerDetail(color: color)
                        }
                    }
                }
                Spacer()
                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("Customize Your Cup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Could not find your profile! Try restarting the app", isPresented: $userNotFound) {
            Button("Ok") { userNotFound = false }
        }
        .onDisappear {
            Task {
                do {
                    async let _ = try await coffeeculeManager.update(coffeeculeManager.user)
                    if let user = coffeeculeManager.user {
                        async let _ = coffeeculeManager.updateTransactions(withNewNameFrom: user)
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    GeometryReader { geo in
        CustomizeCupView()
    }
}
