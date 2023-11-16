//
//  MockDataContainer.swift
//  CoffeeculeTDDTests
//
//  Created by Cory Tripathy on 11/13/23.
//

import CloudKit
@testable import CoffeeculeTDD

class MockDataContainer: DataContainer {
    let `public`: Database
    
    private var userAccountStatus: CKAccountStatus
    private var userRecordID: CKRecord.ID

    func userRecordID() async throws -> CKRecord.ID {
        return userRecordID
    }

    func accountStatus() async throws -> CKAccountStatus {
        return self.userAccountStatus
    }
    
    init(with database: Database,
         accountStatus: CKAccountStatus = .available) {
        self.userAccountStatus = accountStatus
        self.public = database
        self.userRecordID = .init(recordName: UUID().uuidString)
    }
    
    required init() {
        self.public = MockDatabase()
        self.userAccountStatus = .available
        self.userRecordID = .init(recordName: UUID().uuidString)
    }
}
