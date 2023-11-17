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
    
    typealias Container = MockDataContainer
    var userID: CKRecord.ID?
    var databaseActionSuccess: Bool
    
    enum CloudKitError: Error {
        case couldNotSaveToDatabase
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
    
    func children<Child, Parent>(of parent: Parent) async throws -> [Child] where Child : CoffeeculeTDD.ChildRecord, Parent : CoffeeculeTDD.Record, Parent == Child.Parent {
        if databaseActionSuccess {
            let child1 = Child(from: parent.ckRecord, with: parent)!
            let child2 = Child(from: parent.ckRecord, with: parent)!
            return [child1, child2]
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
    
    func update<SomeRecord>(record: SomeRecord) async throws where SomeRecord : CoffeeculeTDD.Record {
        if databaseActionSuccess {
            return
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
                Relationship(user: .init(systemUserID: "ID"), coffecule: .init()),
                Relationship(user: .init(systemUserID: "ID"), coffecule: .init())
                ]
            return relationships as! [Child]
        } else {
            throw CloudKitError.couldNotSaveToDatabase
        }
    }
    
    init(didAuthenticate: Bool = true, databaseActionSuccess: Bool = true) async {
        self.userID = didAuthenticate ? CKRecord.ID.init(recordName: UUID().uuidString) : nil
        self.databaseActionSuccess = databaseActionSuccess
    }
}

