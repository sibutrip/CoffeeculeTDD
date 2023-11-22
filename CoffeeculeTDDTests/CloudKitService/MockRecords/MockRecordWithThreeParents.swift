//
//  MockRecordWithThreeParents.swift
//  CoffeeculeTDDTests
//
//  Created by Cory Tripathy on 11/17/23.
//

import CloudKit
@testable import CoffeeculeTDD

struct MockRecordWithThreeParents: ChildWithThreeParents {
    
    init?(from record: CKRecord, firstParent: MockRecord, secondParent: SecondMockRecord) {
        return nil
    }
    
    var thirdParent: SecondMockRecord?

    var secondParent: SecondMockRecord?
    
    var parent: MockRecord?
    
    enum RecordKeys: String, CaseIterable {
        case none
    }
    
    static var recordType = "MockRecordWithThreeParents"
    
    var id: String
    
    var creationDate: Date?
    
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
    
    init(firstParent: MockRecord, with thirdParent: SecondMockRecord) {
        self.id = UUID().uuidString
        self.parent = firstParent
        self.thirdParent = thirdParent
    }
    
    init?(from record: CKRecord, firstParent: MockRecord, secondParent: SecondMockRecord, thirdParent: SecondMockRecord) {
        self.id = record.recordID.recordName
        self.creationDate = record.creationDate
        self.parent = firstParent
        self.secondParent = secondParent
        self.thirdParent = thirdParent
    }
    
    init(parent: MockRecord, secondParent: SecondMockRecord, thirdParent: SecondMockRecord) {
        self.id = UUID().uuidString
        self.parent = parent
        self.secondParent = secondParent
        self.thirdParent = thirdParent
    }
}
