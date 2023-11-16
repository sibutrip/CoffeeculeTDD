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
            return [Coffeecule(), Coffeecule()]
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
    
    func save<Child, Parent>(_ record: Child, withParent parent: Parent) async throws where Child : CoffeeculeTDD.ChildRecord, Parent : CoffeeculeTDD.Record, Parent == Child.Parent, Child.RecordKeys.AllCases == [Child.RecordKeys] {
        if databaseActionSuccess {
            return
        } else {
            throw CloudKitError.couldNotSaveToDatabase
        }
    }
    
    init(didAuthenticate: Bool = true, databaseActionSuccess: Bool = true) async {
        self.userID = didAuthenticate ? CKRecord.ID.init(recordName: UUID().uuidString) : nil
        self.databaseActionSuccess = databaseActionSuccess
    }
}

