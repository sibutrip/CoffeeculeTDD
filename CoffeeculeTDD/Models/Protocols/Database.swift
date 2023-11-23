//
//  Database.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/11/23.
//

import CloudKit

protocol Database {
    
    func record(for recordID: CKRecord.ID) async throws -> CKRecord
        
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

extension CKDatabase: Database {
    func modifyRecords(saving recordsToSave: [CKRecord], deleting recordIDsToDelete: [CKRecord.ID]) async throws -> (saveResults: [CKRecord.ID : Result<CKRecord, Error>], deleteResults: [CKRecord.ID : Result<Void, Error>]) {
        return try await self.modifyRecords(saving: recordsToSave, deleting: recordIDsToDelete)
    }
}
