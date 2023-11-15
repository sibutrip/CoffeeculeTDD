//
//  MockDatabase.swift
//  CoffeeculeTDDTests
//
//  Created by Cory Tripathy on 11/13/23.
//

import CloudKit
@testable import CoffeeculeTDD

actor MockDatabase: Database {
    
    private var records: [CKRecord] = [] 
    
    func save(_ record: CKRecord) async throws -> CKRecord {
        if records.contains(where: {$0.recordID == record.recordID }) {
            throw NSError(domain: "record already in database", code: 0)
        }
        records.append(record)
        return records.first { $0.recordID == record.recordID }!
    }
    
    func records(matching query: CKQuery, inZoneWith zoneID: CKRecordZone.ID? = nil, desiredKeys: [CKRecord.FieldKey]? = nil, resultsLimit: Int = CKQueryOperation.maximumResults) async throws -> (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?) {
        let results = records.map { record in
            let result: Result<CKRecord, any Error> = .success(record)
            return (record.recordID, result)
        }
        return (matchResults: results, queryCursor: nil)
    }
    
    func modifyRecords(saving recordsToSave: [CKRecord], deleting recordIDsToDelete: [CKRecord.ID]) async throws -> (saveResults: [CKRecord.ID : Result<CKRecord, Error>], deleteResults: [CKRecord.ID : Result<Void, Error>]) {
        var savedRecords = [CKRecord]()
        self.records = records.map { existingRecord in
            if recordsToSave.contains(where: { $0.recordID == existingRecord.recordID }) {
                let recordToSave = recordsToSave.first { $0.recordID == existingRecord.recordID } ?? existingRecord
                savedRecords.append(recordToSave)
                return recordToSave
            } else {
                return existingRecord
            }
        }
        if savedRecords.isEmpty {
            throw NSError(domain: "no records modified", code: 0)
        }
        let saveResults: [Result<CKRecord, Error>] = savedRecords.map {
            .success($0)
        }
        let saveIDs = savedRecords.map { $0.recordID }
        let zippedSavedRecords = zip(saveIDs, saveResults)
        let saveResultsWithIDs = Dictionary(uniqueKeysWithValues: zippedSavedRecords)
        return (saveResults: saveResultsWithIDs, deleteResults: [:])
    }
    
    func record(for recordID: CKRecord.ID) async throws -> CKRecord {
        guard let record = records.first(where: { $0.recordID == recordID
        }) else {
            throw NSError(domain: "record not in database", code: 0)
        }
        return record
    }
    
    init(with records: [CKRecord] = []) {
        self.records = records
    }
}
