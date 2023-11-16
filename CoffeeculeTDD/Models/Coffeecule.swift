//
//  Coffeecule.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/12/23.
//

import CloudKit

struct Coffeecule: ChildRecord {
    
    var creationDate: Date?
    
    static let recordType = "Coffeecule"
    
    enum RecordKeys: String, CaseIterable {
        case none
    }
    
    var id: String
    
    var parent: User?
    
    init?(from record: CKRecord, with parent: User? = nil) {
        self.creationDate = record.creationDate
        self.id = record.recordID.recordName
        self.parent = parent
    }
    
    init() {
        self.id = UUID().uuidString
    }
}
