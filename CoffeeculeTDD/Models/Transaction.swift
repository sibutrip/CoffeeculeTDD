//
//  Transaction.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/20/23.
//

import CloudKit

struct Transaction: ChildWithThreeParents {
    init?(from record: CKRecord, firstParent: Coffeecule, secondParent: User, thirdParent: User) {
        self.id = record.recordID.recordName
        self.creationDate = record.creationDate
        self.parent = firstParent
        self.secondParent = secondParent
        self.thirdParent = thirdParent
    }
    
    init?(from record: CKRecord, firstParent: Coffeecule, secondParent: User) {
        fatalError("this init has not been implemenent yet")
    }
    
    init?(from record: CKRecord, with secondParent: User) {
        self.id = record.recordID.recordName
        self.creationDate = record.creationDate
        self.secondParent = secondParent
    }
    
    init?(from record: CKRecord, with parent: Coffeecule) {
        self.id = record.recordID.recordName
        self.creationDate = record.creationDate
        self.parent = parent
    }
    
    init(buyer: User, receiver: User, in coffecule: Coffeecule) {
        self.id = UUID().uuidString
        self.parent = coffecule
        self.secondParent = buyer
        self.thirdParent = receiver
    }
        
    var thirdParent: User?
    
    var secondParent: User?
    
    var parent: Coffeecule?
    
    enum RecordKeys: String, CaseIterable {
        case none
    }
    
    static let recordType = "Transaction"
    
    var id: String
    
    var creationDate: Date?
    
    
}
