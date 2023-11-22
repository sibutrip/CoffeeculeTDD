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
        get async { await ckService?.user }
    }
    var coffeecules: [Coffeecule] = []
    @Published var selectedCoffeecule: Coffeecule?
    
    @Published var usersInSelectedCoffeecule: [User] = []
    
    @Published var transactionsInSelectedCoffeecule: [Transaction] = []
    
    @Published var selectedBuyer: User?
    @Published var selectedReceivers: [User] = []
    
    @Published var isLoading: Bool = true
    @Published var displayedError: Error?
    
    
    enum UserManagerError: Error {
        case noCkServiceAvailable, failedToConnectToDatabase, noCoffeeculeSelected, noBuyerSelected, noReceiversSelected
    }
    
    func createCoffeecule() async throws {
        guard let user = await user,
              let ckService else {
            throw UserManagerError.noCkServiceAvailable
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
            throw UserManagerError.noCkServiceAvailable
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
            throw UserManagerError.noCkServiceAvailable
        }
        do {
            let relationships: [Relationship] = try await ckService.twoParentChildren(of: nil, secondParent: selectedCoffeecule)
            self.usersInSelectedCoffeecule = relationships.compactMap { $0.parent }
        } catch {
            throw UserManagerError.failedToConnectToDatabase
        }
    }
    
    func addTransaction() async throws {
        guard let selectedBuyer else {
            throw UserManagerError.noBuyerSelected
        }

        guard let selectedCoffeecule else {
            throw UserManagerError.noCoffeeculeSelected
        }
        
        guard let ckService else {
            throw UserManagerError.noCkServiceAvailable
        }
        
        guard !selectedReceivers.isEmpty else {
            throw UserManagerError.noReceiversSelected
        }
        
        let transactions = selectedReceivers.map {
            Transaction(buyer: selectedBuyer, receiver: $0, in: selectedCoffeecule)
        }
        for transaction in transactions {
            async let _ = try await ckService.saveWithThreeParents(transaction)
        }
        self.transactionsInSelectedCoffeecule += transactions
    }
    
    init() { }
}
