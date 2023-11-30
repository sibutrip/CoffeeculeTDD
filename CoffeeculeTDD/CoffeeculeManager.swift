//
//  CoffeeculeManager.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/15/23.
//

import SwiftUI
import CloudKit

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
    @Published var selectedBuyer: User? {
        didSet {
            print(selectedBuyer?.name ?? "none")
        }
    }
    
    /// [buyer: [receiver: debtAmount]]
    @Published var userRelationships: [User: [User: Int]] = [:]
    
    @Published var selectedUserDebts: [User: Int] = [:]
    
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
        if selectedUserDebts.count > 1 {
            self.selectedBuyer = mostInDebtUser.user
        } else {
            self.selectedBuyer = nil
        }
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
    
    func addTransaction() async throws {
        guard !selectedUsers.isEmpty else {
            throw UserManagerError.noReceiversSelected
        }
        
        guard let buyer = selectedBuyer else {
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
    
    func remove(_ transaction: Transaction) async throws {
        guard let ckService else {
            throw UserManagerError.noCkServiceAvailable
        }
        
        try await ckService.remove(transaction)
        self.transactionsInSelectedCoffeecule = transactionsInSelectedCoffeecule.filter { $0.id != transaction.id }
        try createUserRelationships()
    }
    
    func fetchTransactionsInCoffeecule() async throws {
        guard let selectedCoffeecule else {
            throw UserManagerError.noCoffeeculeSelected
        }
        
        guard let ckService else {
            throw UserManagerError.noCkServiceAvailable
        }
        let transactionRecords: [CKRecord]  = (try? await ckService.children(of: selectedCoffeecule, returning: Transaction.self)) ?? []
        let buyerIDs: Set<String> = Set(transactionRecords.compactMap { ($0["Buyer"] as? CKRecord.Reference)?.recordID.recordName })
        let receiverIDs: Set<String> = Set(transactionRecords.compactMap { ($0["Receiver"] as? CKRecord.Reference)?.recordID.recordName })
        let allUserIDs = buyerIDs.union(receiverIDs)
        let usersByReference: [String: User] = Dictionary(
            uniqueKeysWithValues: allUserIDs.compactMap { userID in
                if let user = usersInSelectedCoffeecule.first(where: { $0.recordID.recordName == userID }) {
                    return (userID, user)
                }
                return nil
        })
        let transactions: [Transaction] = transactionRecords.compactMap { record in
            guard let receiverID = (record["Receiver"] as? CKRecord.Reference)?.recordID.recordName,
                  let buyerID = (record["Buyer"] as? CKRecord.Reference)?.recordID.recordName,
                  let secondParent = usersByReference[buyerID],
                  let thirdParent = usersByReference[receiverID] else {
                return nil
            }
            return Transaction(from: record, firstParent: selectedCoffeecule, secondParent: secondParent, thirdParent: thirdParent)
        }
        self.transactionsInSelectedCoffeecule = transactions
    }
    
    init() { }
}
