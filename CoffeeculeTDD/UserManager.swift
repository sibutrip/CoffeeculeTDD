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
    
    @Published var selectedUsers: [User] = []
    
    /// [buyer: [receiver: debtAmount]]
    var userRelationships: [User: [User: Int]] = [:]
    
    var buyerFromSelectedUsers: User?
    var receiversFromSelectedUsers: [User] = []
    
    @Published var isLoading: Bool = true
    @Published var displayedError: Error?
    
    
    enum UserManagerError: Error {
        case noCkServiceAvailable, failedToConnectToDatabase, noCoffeeculeSelected, noBuyerSelected, noReceiversSelected, noUsersFound, invalidTransactionFormat
    }
    
    func createUserRelationships() throws {
        guard !usersInSelectedCoffeecule.isEmpty else {
            throw UserManagerError.noUsersFound
        }
        let userRelationships: [User: [User: Int]] = try transactionsInSelectedCoffeecule.reduce(into: [:]) { partialResult, transaction in
            guard let buyer = transaction.secondParent,
                  let receiver = transaction.thirdParent else {
                throw UserManagerError.invalidTransactionFormat
            }
            
            // if buyer/receiver have no relationships, make a dict with the starting key: value pairs
            guard let buyerRelationships = partialResult[buyer],
            let receiverRelationships = partialResult[receiver] else {
                partialResult[buyer] = [receiver: 1]
                partialResult[receiver] = [buyer: -1]
                return
            }
            
            // if buyer/receiver have existing relationships, but not for this buyer-receiver combination, add this key: value pair to the nested dictionary
            guard let buyerDebt = buyerRelationships[receiver],
                  let receiverDebt = receiverRelationships[buyer] else {
                partialResult[buyer]?[receiver] = 1
                partialResult[receiver]?[buyer] = -1
                return
            }
            
            // otherwise, increment the debt +/- 1
            partialResult[buyer]?[receiver] = buyerDebt + 1
            partialResult[receiver]?[buyer] = receiverDebt - 1
        }
        self.userRelationships = userRelationships
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
        guard let buyerFromSelectedUsers else {
            throw UserManagerError.noBuyerSelected
        }

        guard let selectedCoffeecule else {
            throw UserManagerError.noCoffeeculeSelected
        }
        
        guard let ckService else {
            throw UserManagerError.noCkServiceAvailable
        }
        
        guard !receiversFromSelectedUsers.isEmpty else {
            throw UserManagerError.noReceiversSelected
        }
        
        let transactions = receiversFromSelectedUsers.map {
            Transaction(buyer: buyerFromSelectedUsers, receiver: $0, in: selectedCoffeecule)
        }
        let uploadedTransactions = await withThrowingTaskGroup(of: Transaction.self, returning: [Transaction].self) { group in
            for transaction in transactions {
                group.addTask {
                    try await ckService.saveWithThreeParents(transaction)
                    return transaction
                }
            }
            var uploadedTransactions = [Transaction]()
            while let nextTransaction = try? await group.next() {
                uploadedTransactions.append(nextTransaction)
            }
            return uploadedTransactions
        }
        self.transactionsInSelectedCoffeecule += uploadedTransactions

        if uploadedTransactions.count != transactions.count {
            throw UserManagerError.failedToConnectToDatabase
        }
    }
    
    func fetchTransactionsInCoffeecule() async throws {
        guard let selectedCoffeecule else {
            throw UserManagerError.noCoffeeculeSelected
        }
        
        guard let ckService else {
            throw UserManagerError.noCkServiceAvailable
        }
        
        let transactions: [Transaction] = try await ckService.threeParentChildren(of: selectedCoffeecule, secondParent: nil, thirdParent: nil)
        self.transactionsInSelectedCoffeecule = transactions
    }
    
    init() { }
}
