//
//  User.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/11/23.
//

import CloudKit

struct User: Record {
    static let recordType = "CoffeeculeUser"
    
    enum RecordKeys: String, CaseIterable {
        case systemUserID, name, mugIconString, userColorString
    }
    
    var id: String
    var name: String
    var systemUserID: String
    var creationDate: Date?
    var mugIcon: MugIcon { MugIcon(rawValue: mugIconString) ?? .disposable }
    var userColor: UserColor { UserColor(rawValue: userColorString) ?? .purple }
    var mugIconString: MugIcon.RawValue = "disposable"
    var userColorString: UserColor.RawValue = "purple"
    
    init?(from record: CKRecord) {
        guard let name = record["name"] as? String,
              let systemUserID = record["systemUserID"] as? String else {
            return nil
        }
        self.creationDate = record.creationDate
        self.id = record.recordID.recordName
        self.name = name
        self.systemUserID = systemUserID
        self.mugIconString = record["mugIconString"] as? String ?? "disposable"
        self.userColorString = record["userColorString"] as? String ?? "purple"
    }
    
    init(systemUserID: String) {
        self.name = "TEST"
        self.id = UUID().uuidString
        self.systemUserID = systemUserID
    }
}
