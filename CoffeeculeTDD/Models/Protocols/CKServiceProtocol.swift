//
//  CKServiceProtocol.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/16/23.
//

import CloudKit

protocol CKServiceProtocol: Actor {
    
    associatedtype Container: DataContainer
    associatedtype CloudKitError: Error
    
    var userID: CKRecord.ID? { get set }
            
    func updatedRecord<SomeRecord: Record>(for record: SomeRecord) async throws -> SomeRecord
    
    func authenticate() async throws
    
    func save<SomeRecord: Record>(record: SomeRecord) async throws -> SomeRecord
    
    func fetch<SomeRecord: Record>() async throws -> [SomeRecord]
    
    func children<Child: ChildRecord, Parent: Record>(of parent: Parent) async throws -> [Child] where Child.Parent == Parent
    
    func update<SomeRecord: Record>(record: SomeRecord) async throws
    
    func save<Child: ChildRecord, Parent: Record>(_ record: Child, withParent parent: Parent) async throws where Child.RecordKeys.AllCases == [Child.RecordKeys], Child.Parent == Parent
}

extension CKServiceProtocol {
    public var user: User? {
        guard let userID else { return nil }
        let user = User(systemUserID: userID.recordName)
        let userCkRecord = user.ckRecord
        guard let user = User(from: userCkRecord) else { return nil }
        return user
    }
}
