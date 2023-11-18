//
//  MockRecordWithTwoParents.swift
//  CoffeeculeTDDTests
//
//  Created by Cory Tripathy on 11/17/23.
//

import CloudKit
@testable import CoffeeculeTDD

struct MockRecordWithTwoParents: ChildWithTwoParents {
    init?(from record: CKRecord, firstParent: MockRecord, secondParent: SecondMockRecord) {
        self.id = record.recordID.recordName
        self.parent = firstParent
        self.secondParent = secondParent
        self.parent = firstParent
    }
    
        
    var secondParent: SecondMockRecord?
    
    var parent: MockRecord?
    
    enum RecordKeys: String, CaseIterable {
        case none
    }
    
    static var recordType = "MockRecordWithTwoParents"
    
    var id: String
    
    var creationDate: Date?
    
    init(firstParent: MockRecord, secondParent: SecondMockRecord) {
        self.id = UUID().uuidString
        self.parent = firstParent
        self.secondParent = secondParent
    }
    
    init?(from record: CKRecord, with secondParent: SecondMockRecord) {
        self.id = record.recordID.recordName
        self.secondParent = secondParent
        self.creationDate = record.creationDate
    }
    
    init?(from record: CKRecord, with parent: MockRecord) {
        self.id = record.recordID.recordName
        self.parent = parent
        self.creationDate = record.creationDate
    }
}
