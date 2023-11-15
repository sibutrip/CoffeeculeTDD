//
//  UserManager.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/15/23.
//

import SwiftUI

class UserManager<Container: DataContainer> {
    private var cloudKitService: CloudKitService<Container>?
    var user: User?
    var coffeecules: [Coffeecule]?
    @Published var isLoading: Bool
    @Published var displayedError: Error?
    
    init(with container: Container) {
        isLoading = true
        Task {
            do {
                self.cloudKitService = try await CloudKitService(with: container)
                self.user = await cloudKitService?.user
            } catch {
                displayedError = error
            }
            isLoading = false
        }
    }
}
