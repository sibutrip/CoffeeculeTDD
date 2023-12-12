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
    @Published var user: User?
    @Published var coffeecules: [Coffeecule] = []
    @Published var selectedCoffeecule: Coffeecule?
    
    @Published var usersInSelectedCoffeecule: [User] = []
    
    @Published var transactionsInSelectedCoffeecule: [Transaction] = []
    
    @Published var selectedUsers: [User] = []
    @Published var selectedBuyer: User?
    
    /// [buyer: [receiver: debtAmount]]
    @Published var userRelationships: [User: [User: Int]] = [:]
    
    @Published var selectedUserDebts: [User: Int] = [:]
    
    @Published var isLoading: Bool = true
    @Published var displayedError: Error?
    
    
    enum UserManagerError: LocalizedError {
        case noCkServiceAvailable, failedToConnectToDatabase, noCoffeeculeSelected, noReceiversSelected, noUsersFound, invalidTransactionFormat, noBuyerSelected, coffeeculeNameTaken, noCoffeeculeFound,noCoffeeculeNameGiven, alreadyInCoffeecule
        public var errorDescription: String? {
            switch self {
            case .noCkServiceAvailable:
                NSLocalizedString("No internet found", comment: "Make sure you're connected to the internet and try again")
            case .failedToConnectToDatabase:
                NSLocalizedString("No internet found", comment: "Make sure you're connected to the internet and try again")
            case .noCoffeeculeSelected:
                NSLocalizedString("No Coffeecule selected.", comment: "Select a coffeecule to continue.")
            case .noReceiversSelected:
                NSLocalizedString("No receivers for a transaction", comment: "Reselect who's here")
            case .noUsersFound:
                NSLocalizedString("No users found", comment: "Refresh or relaunch the app")
            case .invalidTransactionFormat:
                NSLocalizedString("Corrupted data", comment: "Refresh or relaunch the app")
            case .noBuyerSelected:
                NSLocalizedString("No buyer selected", comment: "Choose a buyer and try again")
            case .coffeeculeNameTaken:
                NSLocalizedString("Name already used", comment: "Choose a different name and try again")
            case .noCoffeeculeFound:
                NSLocalizedString("Coffeecule not found", comment: "Make sure your invite code is correct and try again")
            case .noCoffeeculeNameGiven:
                NSLocalizedString("No Coffeecule name given", comment: "Enter a name and try again")
            case .alreadyInCoffeecule:
                NSLocalizedString("Already a member of that Coffeecule", comment: "Try a different code, or create your own Coffeecule")
            }
        }
        public var recoverySuggestion: String? {
            switch self {
            case .noCkServiceAvailable:
                "Make sure you're connected to the internet and try again"
            case .failedToConnectToDatabase:
                "Make sure you're connected to the internet and try again"
            case .noCoffeeculeSelected:
                "Select a coffeecule to continue."
            case .noReceiversSelected:
                "Reselect who's here"
            case .noUsersFound:
                "Refresh or relaunch the app"
            case .invalidTransactionFormat:
                "Refresh or relaunch the app"
            case .noBuyerSelected:
                "Choose a buyer and try again"
            case .coffeeculeNameTaken:
                "Choose a different name and try again"
            case .noCoffeeculeFound:
                "Make sure your invite code is correct and try again"
            case .noCoffeeculeNameGiven:
                "Enter a name and try again"
            case .alreadyInCoffeecule:
                "Try a different code, or create your own Coffeecule"
            }
        }
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
    
#warning("should check name updates, adds to coffecules, changes selected coffeecule. add noCoffeeculeNameGiven to tests")
    func createCoffeecule(with name: String) async throws {
        guard let user,
              let ckService else {
            throw UserManagerError.noCkServiceAvailable
        }
        if name.isEmpty {
            throw UserManagerError.noCoffeeculeNameGiven
        }
        if coffeecules.contains(where: {$0.name.lowercased() == name.lowercased() }) {
            throw UserManagerError.coffeeculeNameTaken
        }
        var coffeecule = Coffeecule(with: name)
        var fetchedCule: Coffeecule? = try? await ckService.records(matchingValue: coffeecule.inviteCode, inField: .inviteCode).first
        while fetchedCule != nil {
            coffeecule = Coffeecule(with: name)
            fetchedCule = try? await ckService.records(matchingValue: coffeecule.inviteCode, inField: .inviteCode).first
        }
        let relationship = Relationship(user: user, coffecule: coffeecule)
        do {
            _ = try await ckService.save(record: coffeecule)
            _ = try await ckService.update(record: user, updatingFields: [.name])
            _ = try await ckService.saveWithTwoParents(relationship)
            self.coffeecules.append(coffeecule)
            self.selectedCoffeecule = coffeecule
        } catch {
            throw UserManagerError.failedToConnectToDatabase
        }
    }
    
#warning("add to tests. should check name updates, adds to coffecules, changes selected coffeecule. add already in coffeecule")
    func joinCoffeecule(withInviteCode inviteCode: String) async throws {
        guard let user else { throw UserManagerError.noUsersFound }
        guard let ckService else { throw UserManagerError.noCkServiceAvailable }
        guard let fetchedCoffeecules: [Coffeecule] = try? await ckService.records(matchingValue: inviteCode, inField: .inviteCode) else {
            throw UserManagerError.noCoffeeculeFound
        }
        guard let fetchedCoffeecule = fetchedCoffeecules.first else {
            throw UserManagerError.noCoffeeculeFound
        }
        try await fetchCoffeecules()
        if self.coffeecules.contains(where: { $0.inviteCode == inviteCode}) {
            throw UserManagerError.alreadyInCoffeecule
        }
        let relationship = Relationship(user: user, coffecule: fetchedCoffeecule)
        do {
            _ = try await ckService.update(record: user, updatingFields: [.name])
            try await ckService.saveWithTwoParents(relationship)
            self.coffeecules.append(fetchedCoffeecule)
            self.selectedCoffeecule = fetchedCoffeecule
        } catch {
            throw UserManagerError.failedToConnectToDatabase
        }
    }
    
    func fetchCoffeecules() async throws {
        guard let user,
              let ckService else {
            throw UserManagerError.noCkServiceAvailable
        }
        do {
            let relationships: [Relationship] = try await ckService.twoParentChildren(of: user, secondParent: nil)
            self.coffeecules = relationships
                .compactMap { $0.secondParent }
                .sorted { $0.name < $1.name}
        } catch {
            throw UserManagerError.failedToConnectToDatabase
        }
    }
    
    func fetchUsersInCoffeecule() async throws {
        guard let user else {
            throw UserManagerError.noUsersFound
        }
        guard let selectedCoffeecule else {
            throw UserManagerError.noCoffeeculeSelected
        }
        guard let ckService else {
            throw UserManagerError.noCkServiceAvailable
        }
        do {
            let relationships: [Relationship] = try await ckService.twoParentChildren(of: nil, secondParent: selectedCoffeecule)
            var usersInSelectedCoffeecule = relationships
                .compactMap { $0.parent }
            if !usersInSelectedCoffeecule.contains(where: {user.id == $0.id}) {
                usersInSelectedCoffeecule.append(user)
            }
            self.usersInSelectedCoffeecule = usersInSelectedCoffeecule
                .sorted { $0.name < $1.name}
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
    
    func update(_ userToUpdate: User?) async throws {
        guard let userToUpdate else {
            throw UserManagerError.noUsersFound
        }
        self.user = userToUpdate
        self.usersInSelectedCoffeecule = usersInSelectedCoffeecule.map { user in
            return user.id == userToUpdate.id ? userToUpdate : user
        }
        _ = try await ckService?.update(record: userToUpdate, updatingFields: [.mugIconString, .userColorString, .name])
    }
    
    func updateTransactions(withNewNameFrom user: User) {
        self.transactionsInSelectedCoffeecule = self.transactionsInSelectedCoffeecule.map { transaction in
            var transaction = transaction
            if transaction.secondParent?.id == user.id {
                transaction.secondParent = user
            } else if transaction.thirdParent?.id == user.id {
                transaction.thirdParent = user
            }
            return transaction
        }
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
