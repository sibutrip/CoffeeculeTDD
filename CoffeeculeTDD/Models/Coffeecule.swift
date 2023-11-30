//
//  Coffeecule.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/12/23.
//

import CloudKit

struct Coffeecule: Record {
    init?(from record: CKRecord) {
        guard let shortCode = record[Coffeecule.RecordKeys.shortCode.rawValue] as? String,
        let name = record[Coffeecule.RecordKeys.name.rawValue] as? String else {
            return nil
        }
        self.shortCode = shortCode
        self.name = name
        self.creationDate = record.creationDate
        self.id = record.recordID.recordName
    }
    
    var creationDate: Date?
    
    static let recordType = "Coffeecule"
    
    enum RecordKeys: String, CaseIterable {
        case shortCode, name
    }
    
    var id: String
    var shortCode: String
    var name: String
    
    init(with name: String) {
        self.id = UUID().uuidString
        self.name = name
        self.shortCode = String((0..<8).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890".randomElement()! })
    }
}
