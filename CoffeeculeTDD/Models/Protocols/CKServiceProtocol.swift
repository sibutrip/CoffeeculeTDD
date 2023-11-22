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
    
    func saveWithOneParent<Child: ChildRecord, Parent: Record>(_ record: Child) async throws where Child.RecordKeys.AllCases == [Child.RecordKeys], Child.Parent == Parent
    
    func saveWithTwoParents<Child: ChildWithTwoParents, FirstParent: Record, SecondParent: Record>(_ record: Child) async throws where Child.Parent == FirstParent, Child.SecondParent == SecondParent
    
    func saveWithThreeParents<Child: ChildWithThreeParents, FirstParent: Record, SecondParent: Record, ThirdParent: Record>(_ record: Child) async throws where Child.Parent == FirstParent, Child.SecondParent == SecondParent, Child.ThirdParent == ThirdParent
    
    func twoParentChildren<Child: ChildWithTwoParents, FirstParent: Record, SecondParent: Record>(of parent: FirstParent?, secondParent: SecondParent?) async throws -> [Child] where Child : ChildRecord, FirstParent : Record, FirstParent == Child.Parent, SecondParent == Child.SecondParent
    
    func threeParentChildren<Child: ChildWithThreeParents, FirstParent: Record, SecondParent: Record, ThirdParent: Record>(of parent: FirstParent?, secondParent: SecondParent?, thirdParent: ThirdParent?) async throws -> [Child] where Child : ChildRecord, FirstParent : Record, FirstParent == Child.Parent, SecondParent == Child.SecondParent, ThirdParent == Child.ThirdParent
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
