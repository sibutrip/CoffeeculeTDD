//
//  CloudKitService.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/11/23.
//

import CloudKit

protocol DataStore {
    
    func save(_ record: CKRecord) async throws -> CKRecord
    
    func records(
        matching query: CKQuery,
        inZoneWith zoneID: CKRecordZone.ID?,
        desiredKeys: [CKRecord.FieldKey]?,
        resultsLimit: Int
    ) async throws -> (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?)
    
    func modifyRecords(
        saving recordsToSave: [CKRecord],
        deleting recordIDsToDelete: [CKRecord.ID]) async throws -> (saveResults: [CKRecord.ID : Result<CKRecord, Error>], deleteResults: [CKRecord.ID : Result<Void, Error>])
    
}

class CloudKitService {
    
    enum CloudKitError: Error {
        case invalidRequest, unexpectedResultFromServer
    }
    
    private let dataStore: DataStore
    
    func save<SomeRecord: Record>(record: SomeRecord) async throws {
        let ckRecord = record.ckRecord
        let _ = try await dataStore.save(ckRecord)
    }
    
    func fetch<SomeRecord: Record>() async throws -> [SomeRecord] {
        let (results,_) = try await dataStore.records(
            matching: CKQuery(recordType: "something", predicate: NSPredicate(value: true)),
            inZoneWith: nil,
            desiredKeys: nil,
            resultsLimit: CKQueryOperation.maximumResults)
        let ckRecords = try results.map { result in
            switch result.1 {
            case .success (let record):
                return record
            case .failure (_):
                throw CloudKitError.invalidRequest
            }
        }
        let someRecords: [SomeRecord] = ckRecords.compactMap { SomeRecord(from: $0) }
        return someRecords
    }
    
    func update<SomeRecord: Record>(record: SomeRecord, fields: [SomeRecord.RecordKeys]) async throws -> SomeRecord{
        let (saveResults,_) = try await dataStore.modifyRecords(saving: [record.ckRecord], deleting: [])
        let ckRecords = try saveResults.map { result in
            switch result.1 {
            case .success (let record):
                return record
            case .failure (_):
                throw CloudKitError.invalidRequest
            }
        }
        let someRecords: [SomeRecord] = ckRecords.compactMap { SomeRecord(from: $0) }
        guard let modifiedRecord = someRecords.first else {
            throw CloudKitError.unexpectedResultFromServer
        }
        return modifiedRecord
        
    }
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
}


