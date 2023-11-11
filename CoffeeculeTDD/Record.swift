//
//  Record.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/11/23.
//

import CloudKit

protocol Record: Identifiable, Hashable {
    /// The record type that CloudKit uses as an identifier for each table of records.
    ///
    /// Usage:
    /// - Make sure to set this value to correspond to what you want the CKRecord.RecordType to be in CloudKit.
    static var recordType: String { get }
    
    /// RecordKeys represents the names of each field of a CKRecord to be stored in CloudKit.
    ///
    /// Usage:
    /// - Implement a RecordKeys enum for each type that conforms to the Record protocol.
    /// - Each case of RecordKeys should match a property named in a Record type exactly.
    /// - Do not include `id` in RecordKeys, because CKRecord.ID handles this separately.
    /// - Do not include parents, children, or other properties that reference custom types or relationships in RecordKeys. To establish these relationships in CloudKit, use CloudKitService methods for parents and children AND set values locally.
    associatedtype RecordKeys: RawRepresentable, CaseIterable where RecordKeys.RawValue: StringProtocol
    
    /// An id that reflects the UUID "Name" property for CloudKit records, or CKRecord.ID for local records.
    /// You can also use `SomeRecord.recordID` for an id that is typed CKRecord.ID.
    ///
    /// Usage:
    /// - When initializing a Record type, use
    /// ```
    /// self = SomeRecord(id: record.recordID.recordName, ...)
    /// ```
    var id: String { get }
    
    /// Initializes an instance of a Record type from a CKRecord.
    init?(from record: CKRecord)
}

extension Record {
    /// An id that reflects the UUID "Name" property for CloudKit records, as a CKRecord.ID.
    ///
    /// You can also use SomeRecord.id for an id that is typed String.
    var recordID: CKRecord.ID {
        ckRecord.recordID
    }
    
    /// All cases of a Record type's RecordKeys enum.
    static var recordKeys: [String] {
        RecordKeys.allCases.compactMap { $0.rawValue as? String }
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
                record.setValue(propertyLabel.value, forKey: recordKey)
            }
        }
        return record
    }
    
    // MARK: Hashable conformance
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
