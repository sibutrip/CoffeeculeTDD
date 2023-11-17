//
//  Relationship.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/14/23.
//

import CloudKit

struct Relationship: ChildWithTwoParents {
    init?(from record: CKRecord, firstParent: User, secondParent: Coffeecule) {
        self.id = UUID().uuidString
        self.parent = firstParent
        self.secondParent = secondParent
        self.parent = firstParent
    }
    
    var creationDate: Date?
    
    static var recordType: String { "Coffeecule" }
    
    enum RecordKeys: String, CaseIterable {
        case id
    }
    
    enum ParentKeys: String, CaseIterable {
        case user, coffeecule
    }
    
    var parent: User?
    var secondParent: Coffeecule?
    
    var id: String
    
    init(user: User, coffecule: Coffeecule) {
        self.id = UUID().uuidString
        self.parent = user
        self.secondParent = coffecule
    }
    
    init(from record: CKRecord, with coffeecule: Coffeecule) {
        self.creationDate = record.creationDate
        self.id = record.recordID.recordName
        self.secondParent = coffeecule
    }
    
    init(from record: CKRecord, with user: User) {
        self.creationDate = record.creationDate
        self.id = record.recordID.recordName
        self.parent = user
    }
}
