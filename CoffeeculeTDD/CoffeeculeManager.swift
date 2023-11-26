//
//  CoffeeculeManager.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/15/23.
//

import SwiftUI

@MainActor
class CoffeeculeManager<CKService: CKServiceProtocol>: ObservableObject {
    
    var ckService: CKService?
    var user: User? {
        get async { await ckService?.user }
    }
    @Published var coffeecules: [Coffeecule] = []
    @Published var selectedCoffeecule: Coffeecule?
    
    @Published var usersInSelectedCoffeecule: [User] = [] 
    
    @Published var transactionsInSelectedCoffeecule: [Transaction] = []
    
    @Published var selectedUsers: [User] = []
    
    /// [buyer: [receiver: debtAmount]]
    @Published var userRelationships: [User: [User: Int]] = [:]
    
    private var selectedUserDebts: [User: Int] = [:]
//    {
//        let userDebts: [User: Int] = Dictionary(
//            uniqueKeysWithValues: userRelationships.compactMap { (buyer, receiverRelationship) in
//                if selectedUsers.contains(where: {$0 == buyer }) {
//                    let debt = receiverRelationship.reduce(0) { partialResult, receiverDebt in
//                        if selectedUsers.contains(where: {$0 == receiverDebt.key }) {
//                            return partialResult + receiverDebt.value
//                        }
//                        return partialResult
//                    }
//                    return (buyer, debt)
//                }
//                return nil
//            }
//        )
//        return userDebts
//    }
    
    var mostIndebttedFromSelectedUsers: User? 
//    {
//        let mostInDebtUser: (user: User?, debt: Int) = selectedUserDebts.reduce((User?.none, Int.max)) { partialResult, buyerDebts in
//            if buyerDebts.1 <= partialResult.1 {
//                return buyerDebts
//            }
//            return partialResult
//        }
//        return mostInDebtUser.user
//    }
        
    @Published var isLoading: Bool = true
    @Published var displayedError: Error?
    
    
    enum UserManagerError: Error {
        case noCkServiceAvailable, failedToConnectToDatabase, noCoffeeculeSelected, noReceiversSelected, noUsersFound, invalidTransactionFormat, noBuyerSelected
    }
    
    func createUserRelationships() throws {
        let emptyRelationships: [User: [User: Int]] = Dictionary(
            uniqueKeysWithValues: usersInSelectedCoffeecule.map { buyer in
                let receiverRelationships = Dictionary(
                    uniqueKeysWithValues: usersInSelectedCoffeecule.compactMap { receiver in
                        if receiver != buyer {
                            return (receiver, 0)
                        }
                        return nil
                    }
                )
                return (buyer, receiverRelationships)
            }
        )
        let userRelationships: [User: [User: Int]] = try transactionsInSelectedCoffeecule.reduce(into: emptyRelationships) { partialResult, transaction in
            guard let buyer = transaction.secondParent,
                  let receiver = transaction.thirdParent else {
                throw UserManagerError.invalidTransactionFormat
            }
            
            guard let buyerDebt = partialResult[buyer]?[receiver],
                  let receiverDebt = partialResult[receiver]?[buyer] else {
                partialResult[buyer]?[receiver] = 1
                partialResult[receiver]?[buyer] = -1
                return
            }
            
            partialResult[buyer]?[receiver] = buyerDebt + 1
            partialResult[receiver]?[buyer] = receiverDebt - 1
        }
        self.userRelationships = userRelationships
        let userDebts: [User: Int] = Dictionary(
            uniqueKeysWithValues: userRelationships.compactMap { (buyer, receiverRelationship) in
                if selectedUsers.contains(where: {$0 == buyer }) {
                    let debt = receiverRelationship.reduce(0) { partialResult, receiverDebt in
                        if selectedUsers.contains(where: {$0 == receiverDebt.key }) {
                            return partialResult + receiverDebt.value
                        }
                        return partialResult
                    }
                    return (buyer, debt)
                }
                return nil
            }
        )
        self.selectedUserDebts = userDebts
        let mostInDebtUser: (user: User?, debt: Int) = selectedUserDebts.reduce((User?.none, Int.max)) { partialResult, buyerDebts in
            if buyerDebts.1 <= partialResult.1 {
                return buyerDebts
            }
            return partialResult
        }
        self.mostIndebttedFromSelectedUsers = mostInDebtUser.user
    }
    
    func createCoffeecule() async throws {
        guard let user = await user,
              let ckService else {
            throw UserManagerError.noCkServiceAvailable
        }
        let coffeecule = Coffeecule()
        let relationship = Relationship(user: user, coffecule: coffeecule)
        do {
            _ = try await ckService.save(record: coffeecule)
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
    
    func addTransaction(withBuyer buyer: User?) async throws {
        guard !selectedUsers.isEmpty else {
            throw UserManagerError.noReceiversSelected
        }
        
        guard let buyer else {
            throw UserManagerError.noBuyerSelected
        }

        guard let selectedCoffeecule else {
            throw UserManagerError.noCoffeeculeSelected
        }
        
        guard let ckService else {
            throw UserManagerError.noCkServiceAvailable
        }
        
        let transactions = selectedUsers.compactMap { receiver in
            if buyer != receiver {
                return Transaction(buyer: buyer, receiver: receiver, in: selectedCoffeecule)
            }
            return nil
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
        try createUserRelationships()
    }
    
    func fetchTransactionsInCoffeecule() async throws {
        guard let selectedCoffeecule else {
            throw UserManagerError.noCoffeeculeSelected
        }
        
        guard let ckService else {
            throw UserManagerError.noCkServiceAvailable
        }
        
        let transactions: [Transaction] = (try? await ckService.threeParentChildren(of: selectedCoffeecule, secondParent: nil, thirdParent: nil)) ?? []
        self.transactionsInSelectedCoffeecule = transactions
    }
    
    init() { }
}
