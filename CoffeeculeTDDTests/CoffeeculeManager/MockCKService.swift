//
//  MockCKService.swift
//  CoffeeculeTDDTests
//
//  Created by Cory Tripathy on 11/16/23.
//

import Foundation
import CloudKit
@testable import CoffeeculeTDD

actor MockCKService: CKServiceProtocol {
    
    let selectedCoffeecule = Coffeecule(with: UUID().uuidString)
    let usersInSelectedCoffeecule: [User] = [
        User(systemUserID: UUID().uuidString),
        User(systemUserID: UUID().uuidString)
    ]
    
    var user: User?
    
    typealias Container = MockDataContainer
    var databaseActionSuccess: Bool
    
    enum CloudKitError: Error {
        case couldNotSaveToDatabase
    }
    
    func records<SomeRecord>(matchingValue value: CVarArg, inField field: SomeRecord.RecordKeys) async throws -> [SomeRecord] where SomeRecord : CoffeeculeTDD.Record {
        return []
    }
    
    func remove<SomeRecord>(_ record: SomeRecord) async throws where SomeRecord : CoffeeculeTDD.Record {
        return
    }
    
    func updatedRecord<SomeRecord>(for record: SomeRecord) async throws -> SomeRecord where SomeRecord : CoffeeculeTDD.Record {
        if databaseActionSuccess {
            return record
        } else {
            throw CloudKitError.couldNotSaveToDatabase
        }
    }
    
    func authenticate() async throws {
        if databaseActionSuccess {
            return
        } else {
            throw CloudKitError.couldNotSaveToDatabase
        }
    }
    
    func save<SomeRecord>(record: SomeRecord) async throws -> SomeRecord where SomeRecord : CoffeeculeTDD.Record {
        if databaseActionSuccess {
            return record
        } else {
            throw CloudKitError.couldNotSaveToDatabase
        }
    }
    
    func fetch<SomeRecord>() async throws -> [SomeRecord] where SomeRecord : CoffeeculeTDD.Record {
        if databaseActionSuccess {
            return []
        } else {
            throw CloudKitError.couldNotSaveToDatabase
        }
    }
    
    func children<Parent, Child>(of parent: Parent, returning child: Child.Type) async throws -> [CKRecord] where Parent : CoffeeculeTDD.Record, Parent == Child.Parent, Child : CoffeeculeTDD.ChildRecord {
        if databaseActionSuccess {
            if child.recordType == "Transaction" {
                let record1 = CKRecord(recordType: "Relationship")
                let record2 = CKRecord(recordType: "Relationship")
                let buyer =  usersInSelectedCoffeecule[0].ckRecord
                let receiver =  usersInSelectedCoffeecule[1].ckRecord
                record1["Buyer"] = CKRecord.Reference(record: buyer, action: .none)
                record1["Receiver"] = CKRecord.Reference(record: receiver, action: .none)
                record2["Buyer"] = CKRecord.Reference(record: buyer, action: .none)
                record2["Receiver"] = CKRecord.Reference(record: receiver, action: .none)
                return [record1, record2]
            } else {
                return [CKRecord(recordType: "Test"), CKRecord(recordType: "Test")]
            }
        } else {
            throw CloudKitError.couldNotSaveToDatabase
        }
    }
    
    func saveWithTwoParents<Child: ChildWithTwoParents, FirstParent: Record, SecondParent: Record>(_ record: Child) async throws where Child.Parent == FirstParent, Child.SecondParent == SecondParent {
        if databaseActionSuccess {
            return
        } else {
            throw CloudKitError.couldNotSaveToDatabase
        }
    }
    
    func update<SomeRecord>(record: SomeRecord, updatingFields fields: [SomeRecord.RecordKeys]) async throws -> SomeRecord where SomeRecord : CoffeeculeTDD.Record {
        if databaseActionSuccess {
            return record
        } else {
            throw CloudKitError.couldNotSaveToDatabase
        }
    }
    func saveWithOneParent<Child, Parent>(_ record: Child) async throws where Child : CoffeeculeTDD.ChildRecord, Parent : CoffeeculeTDD.Record, Parent == Child.Parent, Child.RecordKeys.AllCases == [Child.RecordKeys] {
        if databaseActionSuccess {
            return
        } else {
            throw CloudKitError.couldNotSaveToDatabase
        }
    }
    
    func twoParentChildren<Child: ChildWithTwoParents, FirstParent: Record, SecondParent: Record>(of parent: FirstParent? = nil, secondParent: SecondParent? = nil) async throws -> [Child] where Child : ChildRecord, FirstParent : Record, FirstParent == Child.Parent, SecondParent == Child.SecondParent {
        if databaseActionSuccess {
            let relationships = [
                Relationship(user: .init(systemUserID: UUID().uuidString), coffecule: .init(with: UUID().uuidString)),
                Relationship(user: .init(systemUserID: UUID().uuidString), coffecule: .init(with: UUID().uuidString)),
                Relationship(user: .init(systemUserID: UUID().uuidString), coffecule: .init(with: UUID().uuidString)),
                Relationship(user: .init(systemUserID: UUID().uuidString), coffecule: .init(with: UUID().uuidString))
                ]
            return relationships as! [Child]
        } else {
            throw CloudKitError.couldNotSaveToDatabase
        }
    }
    
    func saveWithThreeParents<Child, FirstParent, SecondParent, ThirdParent>(_ record: Child) async throws where Child : CoffeeculeTDD.ChildWithThreeParents, FirstParent : CoffeeculeTDD.Record, FirstParent == Child.Parent, SecondParent : CoffeeculeTDD.Record, SecondParent == Child.SecondParent, ThirdParent : CoffeeculeTDD.Record, ThirdParent == Child.ThirdParent {
        if databaseActionSuccess {
            return
        } else {
            throw CloudKitError.couldNotSaveToDatabase
        }
    }
    
    func threeParentChildren<Child: ChildWithThreeParents, FirstParent: Record, SecondParent: Record, ThirdParent: Record>(of parent: FirstParent? = nil, secondParent: SecondParent? = nil, thirdParent: ThirdParent? = nil) async throws -> [Child] where Child : ChildRecord, FirstParent : Record, FirstParent == Child.Parent, SecondParent == Child.SecondParent, ThirdParent == Child.ThirdParent {
        if databaseActionSuccess {
            let transactions = [
                Transaction(buyer: User(systemUserID: UUID().uuidString), receiver: User(systemUserID: UUID().uuidString), in: Coffeecule(with: UUID().uuidString)),
                Transaction(buyer: User(systemUserID: UUID().uuidString), receiver: User(systemUserID: UUID().uuidString), in: Coffeecule(with: UUID().uuidString)),
                Transaction(buyer: User(systemUserID: UUID().uuidString), receiver: User(systemUserID: UUID().uuidString), in: Coffeecule(with: UUID().uuidString)),
                Transaction(buyer: User(systemUserID: UUID().uuidString), receiver: User(systemUserID: UUID().uuidString), in: Coffeecule(with: UUID().uuidString))
                ]
            return transactions as! [Child]
        } else {
            throw CloudKitError.couldNotSaveToDatabase
        }
    }
    
    init(didAuthenticate: Bool = true, databaseActionSuccess: Bool = true) async {
        self.user = didAuthenticate ? User(systemUserID: "Test") : nil
        self.databaseActionSuccess = databaseActionSuccess
    }
}

