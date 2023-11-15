//
//  Relationship.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/14/23.
//

import CloudKit

struct Relationship<Parent: Record>: ChildRecord {
    var creationDate: Date?
    
    static var recordType: String { "Coffeecule" }
    
    enum RecordKeys: String, CaseIterable {
        case id
    }
    
    var parent: Parent?
    
    var id: String
    
    init?(from record: CKRecord, with parent: Parent? = nil) {
        self.creationDate = record.creationDate
        self.id = record.recordID.recordName
        self.parent = parent
    }
}
