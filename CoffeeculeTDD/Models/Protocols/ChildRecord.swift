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
    /// Initializes an instance of a Record type from a CKRecord, when the parent Record is not available.
    init?(from record: CKRecord) {
        self.init(from: record, with: nil)
    }
    
    /// A CKRecord that reflects the local version of a Record type.
    ///
    /// This is computed each time it is used, by comparing RecordKeys cases with the properties of the record.
    var ckRecord: CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        let propertiesMirrored = Mirror(reflecting: self)
        for recordKey in Self.recordKeys {
            if let propertyLabel = propertiesMirrored.children.first(where: { label, value in
                guard let label = label else {
                    return false
                }
                return label == recordKey
            }) {
                if propertyLabel.label == "parent" {
                    if let parent = propertyLabel.value as? Parent {
                        let reference = CKRecord.Reference(record: parent.ckRecord, action: .none)
                        record.setValue(reference, forKey: recordKey)
                    }
                } else {
                    record.setValue(propertyLabel.value, forKey: recordKey)
                }
            }
        }
        return record
    }
}
