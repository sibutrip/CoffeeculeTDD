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
        case noCKServiceAvailable
    }
    
    func createCoffeecule() async throws {
        guard let user = await user,
              let ckService else {
            throw UserManagerError.noCKServiceAvailable
        }
        let coffeecule = Coffeecule()
        let relationship = Relationship(with: user, in: coffeecule)
        try await ckService.save(relationship, withParent: user)
        self.coffeecules.append(coffeecule)
    }
    
    func fetchCoffeecules() async throws {
        guard let user = await user,
              let ckService else {
            throw UserManagerError.noCKServiceAvailable
        }
        let relationships: [Relationship] = try await ckService.children(of: user)
        self.coffeecules = relationships.compactMap { $0.secondParent }
    }
    
    init() { }
}
