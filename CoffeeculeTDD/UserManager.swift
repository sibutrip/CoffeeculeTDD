//
//  CoffeeculeManager.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/15/23.
//

import SwiftUI

@MainActor
class CoffeeculeManager<CKService: CKServiceProtocol> {
    
    var ckService: CKService?
    var user: User? {
        get async { await ckService!.user }
    }
    var coffeecules: [Coffeecule] = []
    @Published var selectedCoffeecule: Coffeecule?
    
    @Published var usersInSelectedCoffeecule: [User] = []
    
    @Published var isLoading: Bool = true
    @Published var displayedError: Error?
    
    
    enum UserManagerError: Error {
        case noCKServiceAvailable, failedToConnectToDatabase, noCoffeeculeSelected
    }
    
    func createCoffeecule() async throws {
        guard let user = await user,
              let ckService else {
            throw UserManagerError.noCKServiceAvailable
        }
        let coffeecule = Coffeecule()
        let relationship = Relationship(user: user, coffecule: coffeecule)
        do {
            _ = try await ckService.saveWithTwoParents(relationship)
            self.coffeecules.append(coffeecule)
        } catch {
            throw UserManagerError.failedToConnectToDatabase
        }
    }
    
    func fetchCoffeecules() async throws {
        guard let user = await user,
              let ckService else {
            throw UserManagerError.noCKServiceAvailable
        }
        do {
            let relationships: [Relationship] = try await ckService.twoParentChildren(of: user, secondParent: nil)
            self.coffeecules = relationships.compactMap { $0.secondParent }
        } catch {
            throw UserManagerError.failedToConnectToDatabase
        }
    }
    
    func fetchUsersInCoffeecule() async throws {
        guard let selectedCoffeecule else {
            throw UserManagerError.noCoffeeculeSelected
        }
        guard let ckService else {
            throw UserManagerError.noCKServiceAvailable
        }
        do {
            let relationships: [Relationship] = try await ckService.twoParentChildren(of: nil, secondParent: selectedCoffeecule)
            self.usersInSelectedCoffeecule = relationships.compactMap { $0.parent }
        } catch {
            throw UserManagerError.failedToConnectToDatabase
        }
    }
    
    init() { }
}
