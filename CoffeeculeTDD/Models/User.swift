//
//  User.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/11/23.
//

import CloudKit

struct User: TopLevelRecord {
    static let recordType = "CoffeeculeUser"
    
    enum RecordKeys: String, CaseIterable {
        case systemUserID, name
    }
    
    var id: String
    var name: String
    var systemUserID: String
    var creationDate: Date?
    
    init?(from record: CKRecord) {
        guard let name = record["name"] as? String,
        let systemUserID = record["systemUserID"] as? String else {
            return nil
        }
        self.creationDate = record.creationDate
        self.id = record.recordID.recordName
        self.name = name
        self.systemUserID = systemUserID
    }
    
    init(name: String) {
        self.name = name
        self.id = UUID().uuidString
        systemUserID = ""
    }
}
