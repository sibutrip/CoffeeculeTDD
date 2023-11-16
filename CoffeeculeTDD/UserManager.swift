//
//  UserManager.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/15/23.
//

import SwiftUI

@MainActor
class UserManager<CKService: CKServiceProtocol> {
    
    var ckService: CKService?
    var user: User? {
        get async { await ckService!.user }
    }
    var coffeecules: [Coffeecule] = []
    @Published var isLoading: Bool = true
    @Published var displayedError: Error?
    
    
    enum UserManagerError: Error {
        case failedToFindUser
    }
    
    func createCoffeecule() async throws {
        if let user = await user,
           let ckService {
            let coffeecule = Coffeecule()
            let relationship = Relationship(with: user, in: coffeecule)
            try await ckService.save(relationship, withParent: user)
            self.coffeecules.append(coffeecule)
        }
    }
    
    func fetchCoffeecules() async throws {
        if let user = await user,
           let ckService {
            let relationships: [Relationship] = try await ckService.children(of: user)
            self.coffeecules = relationships.compactMap { $0.secondParent }
        }
    }
    
    init() { }
}
