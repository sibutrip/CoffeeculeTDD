//
//  Coffeecule.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/12/23.
//

import CloudKit

struct Coffeecule: Record {
    init?(from record: CKRecord) {
        self.creationDate = record.creationDate
        self.id = record.recordID.recordName
    }
    
    var creationDate: Date?
    
    static let recordType = "Coffeecule"
    
    enum RecordKeys: String, CaseIterable {
        case none
    }
    
    var id: String
    
    init() {
        self.id = UUID().uuidString
    }

}
