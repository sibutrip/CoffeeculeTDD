//
//  MockRecord.swift
//  CoffeeculeTDDTests
//
//  Created by Cory Tripathy on 11/13/23.
//

import CloudKit
@testable import CoffeeculeTDD

struct MockRecord: TopLevelRecord {
    
    static let recordType = "MockRecord"
    
    enum RecordKeys: String, CaseIterable {
        case testField1, testField2
    }
    
    var id: String
    var testField1: String
    var testField2: String
    var creationDate: Date?
    
    init?(from record: CKRecord) {
        guard let testField1 = record["testField1"] as? String,
        let testField2 = record["testField2"] as? String else {
            return nil
        }
        self.creationDate = record.creationDate
        self.id = record.recordID.recordName
        self.testField1 = testField1
        self.testField2 = testField2
    }
    
    init() {
        self.id = UUID().uuidString
        self.testField1 = UUID().uuidString
        self.testField2 = UUID().uuidString
    }
}
