//
//  Relationship.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/14/23.
//

import CloudKit

struct Relationship: TwoChildRecord {
    var creationDate: Date?
    
    static var recordType: String { "Coffeecule" }
    
    enum RecordKeys: String, CaseIterable {
        case id
    }
    
    var parent: User?
    var secondParent: Coffeecule?
    
    var id: String
    
    init(with user: User, in coffeecule: Coffeecule) {
        self.id = UUID().uuidString
        self.parent = user
        self.secondParent = coffeecule
    }
    
    init?(from record: CKRecord, with coffeecule: Coffeecule? = nil) {
        self.creationDate = record.creationDate
        self.id = record.recordID.recordName
        self.secondParent = coffeecule
    }
    
    init?(from record: CKRecord, with user: User? = nil) {
        self.creationDate = record.creationDate
        self.id = record.recordID.recordName
        self.parent = user
    }
}
