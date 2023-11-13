//
//  TopLevelRecord.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/13/23.
//

import CloudKit

protocol TopLevelRecord: Record { }

extension TopLevelRecord {
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
                record.setValue(propertyLabel.value, forKey: recordKey)
            }
        }
        return record
    }
}
