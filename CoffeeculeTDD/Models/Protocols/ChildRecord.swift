//
//  ChildRecord.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/13/23.
//

import CloudKit

/// A Record type that has a parent that is also a Record type.
///
/// Read the Record documentation for implementation tips.
protocol ChildRecord: Record where Parent: Record {
    /// The parent of a Record, which must also be a Record.
    associatedtype Parent = Record
    /// The parent of a Record, which must also be a Record.
    var parent: Parent? { get set }
    
    /// Initializes an instance of a Record type from a CKRecord, when the parent Record is available.
    init?(from record: CKRecord, with parent: Parent?)
}

extension ChildRecord {
    init?(from record: CKRecord) {
        self.init(from: record, with: nil)
    }
}
