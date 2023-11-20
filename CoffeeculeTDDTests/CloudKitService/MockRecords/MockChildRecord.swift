//
//  MockChildRecord.swift
//  CoffeeculeTDDTests
//
//  Created by Cory Tripathy on 11/13/23.
//

import CloudKit
@testable import CoffeeculeTDD

struct MockChildRecord: ChildRecord {
    
    static let recordType: String = "MockChildRecord"
    
    var id: String
    
    enum RecordKeys: String, CaseIterable {
        case testField
    }
    
    var testField: String
    
    var parent: MockRecord?
    
    var creationDate: Date?
    
    init(withParent parent: MockRecord) {
        self.testField = UUID().uuidString
        self.id = UUID().uuidString
        self.parent = parent
    }
    
    init?(from record: CKRecord, with parent: MockRecord) {
        guard let testField = record[RecordKeys.testField.rawValue] as? String else {
            return nil
        }
        self.creationDate = record.creationDate
        self.testField = testField
        self.id = record.recordID.recordName
        self.parent = parent
    }
}
