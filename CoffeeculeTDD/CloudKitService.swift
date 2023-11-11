//
//  CloudKitService.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/11/23.
//

import CloudKit

class CloudKitService {
    
    func authenticate() async throws -> CKRecord.ID {
        switch try await dataStore.accountStatus() {
        case .available:
            do {
                return try await dataStore.userRecordID()
            } catch {
                throw AuthenticationError.iCloudDriveDisabled
            }
        case .couldNotDetermine:
            throw AuthenticationError.couldNotDetermineAccountStatus
        case .restricted:
            throw AuthenticationError.accountRestricted
        case .noAccount:
            throw AuthenticationError.noAccount
        case .temporarilyUnavailable:
            throw AuthenticationError.accountTemporarilyUnavailable
        @unknown default:
            throw AuthenticationError.couldNotDetermineAccountStatus
        }
    }
    
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
        let ckRecords = results.compactMap { result in
            switch result.1 {
            case .success (let record):
                return record
            case .failure (_):
                return nil
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
    
    init(dataStore: DataStore) async throws {
        self.dataStore = dataStore
        do {
            let _ = try await authenticate()
        } catch {
            throw error
        }
    }
}

extension CloudKitService {
    enum AuthenticationError: LocalizedError, CaseIterable {
        case noAccount, accountRestricted, couldNotDetermineAccountStatus, accountTemporarilyUnavailable, iCloudDriveDisabled
        
        public var errorDescription: String? {
            switch self {
            case .noAccount:
                return NSLocalizedString("Please create or log into an iCloud account in system settings before continuing.", comment: "Error when user does not have an iCloud account.")
            case .accountRestricted:
                return NSLocalizedString("iCloud account is restricted.", comment: "Error when user has a restricted iCloud account.")
            case .couldNotDetermineAccountStatus:
                return NSLocalizedString("There was a problem getting your iCloud account details. Make sure you're connected to the internet and both iCloud and iCloud Drive are enabled in system settings.", comment: "Error when CloudKit cannot determine iCloud account status.")
            case .accountTemporarilyUnavailable:
                return NSLocalizedString("iCloud account temporarily unavailable. Please try again later.", comment: "Error when user's iCloud account is temporarily unavailable.")
            case .iCloudDriveDisabled:
                return NSLocalizedString("Please enable iCloud drive in system settings before continuing.", comment: "Error when iCloud Drive is not enabled for a user.")
            }
        }
    }
}

