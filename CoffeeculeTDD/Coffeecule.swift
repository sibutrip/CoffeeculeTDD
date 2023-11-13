//
//  Coffeecule.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/12/23.
//

import CloudKit

struct Coffeecule: Record {
    static let recordType = "Coffeecule"
    
    enum RecordKeys: String, CaseIterable {
        case coffeeculeIdentifier
    }
    
    var id: String
    var coffeeculeIdentifier: String

    
    init?(from record: CKRecord) {
        guard let coffeeculeIdentifier = record["coffeeculeIdentifier"] as? String else {
            return nil
        }
        self.id = record.recordID.recordName
        self.coffeeculeIdentifier = coffeeculeIdentifier
    }
    
    init(coffeeculeIdentifier: String) {
        self.coffeeculeIdentifier = coffeeculeIdentifier
        self.id = UUID().uuidString
    }
}
