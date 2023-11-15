//
//  UserManager.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/15/23.
//

import SwiftUI
import CloudKit

struct User: Record {
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

class UserManager<Container: DataContainer> {
    private var cloudKitService: CloudKitService<Container>?
    var user: User?
    @Published var isLoading: Bool
    
    init(with container: Container) {
        isLoading = true
        Task {
            self.cloudKitService = try await CloudKitService(with: container)
        }
    }
}
