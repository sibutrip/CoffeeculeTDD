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
    
    var user: User? { get set }
            
    func updatedRecord<SomeRecord: Record>(for record: SomeRecord) async throws -> SomeRecord
    
    func authenticate() async throws
    
    func save<SomeRecord: Record>(record: SomeRecord) async throws -> SomeRecord
    
    func fetch<SomeRecord: Record>() async throws -> [SomeRecord]
    
    func children<Parent: Record, Child: ChildRecord>(of parent: Parent, returning child: Child.Type) async throws -> [CKRecord] where Child.Parent == Parent
    
    func update<SomeRecord: Record>(record: SomeRecord, updatingFields fields: [SomeRecord.RecordKeys]) async throws -> SomeRecord
    
    func records<SomeRecord: Record>(matchingValue value: CVarArg, inField field: SomeRecord.RecordKeys) async throws -> [SomeRecord]
    
    func saveWithOneParent<Child: ChildRecord, Parent: Record>(_ record: Child) async throws where Child.RecordKeys.AllCases == [Child.RecordKeys], Child.Parent == Parent
    
    func saveWithTwoParents<Child: ChildWithTwoParents, FirstParent: Record, SecondParent: Record>(_ record: Child) async throws where Child.Parent == FirstParent, Child.SecondParent == SecondParent
    
    func saveWithThreeParents<Child: ChildWithThreeParents, FirstParent: Record, SecondParent: Record, ThirdParent: Record>(_ record: Child) async throws where Child.Parent == FirstParent, Child.SecondParent == SecondParent, Child.ThirdParent == ThirdParent
    
    func twoParentChildren<Child: ChildWithTwoParents, FirstParent: Record, SecondParent: Record>(of parent: FirstParent?, secondParent: SecondParent?) async throws -> [Child] where Child : ChildRecord, FirstParent : Record, FirstParent == Child.Parent, SecondParent == Child.SecondParent
    
    func remove<SomeRecord: Record>(_ record: SomeRecord) async throws
}
