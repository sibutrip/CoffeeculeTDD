//
//  CloudKitService.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/11/23.
//

import CloudKit

class CloudKitService<Container: DataContainer> {
    
    private var coffeeculeID: String = ""
    private var userID: CKRecord.ID?
    
    var dataStore: DataStore {
        if coffeeculeID.isEmpty { return Container.private }
        guard let userID else { return Container.private }
        return userID.recordName == coffeeculeID ? Container.private : Container.shared
    }
    
    func authenticate() async throws {
        switch try await dataStore.accountStatus() {
        case .available:
            do {
                self.userID = try await dataStore.userRecordID()
                let coffeecules: [Coffeecule] = try await fetch()
                if let coffecule = coffeecules.first {
                    coffeeculeID = coffecule.coffeeculeIdentifier
                }
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
        
    func save<SomeRecord: Record>(record: SomeRecord) async throws {
        do {
            let ckRecord = record.ckRecord
            let _ = try await dataStore.save(ckRecord)
        } catch {
            throw CloudKitError.invalidRequest
        }
    }
    
    func fetch<SomeRecord: Record>() async throws -> [SomeRecord] {
        let (results,_) = try await dataStore.records(
            matching: CKQuery(recordType: SomeRecord.recordType, predicate: NSPredicate(value: true)),
            inZoneWith: nil,
            desiredKeys: nil,
            resultsLimit: CKQueryOperation.maximumResults)
        let ckRecords = results.compactMap { result in
            try? result.1.get()
        }
        let someRecords: [SomeRecord] = ckRecords.compactMap { SomeRecord(from: $0) }
        return someRecords
    }
    
    func update<SomeRecord: Record>(record: SomeRecord, fields: [SomeRecord.RecordKeys]) async throws -> SomeRecord {
        do {
            let (saveResults,_) = try await dataStore.modifyRecords(saving: [record.ckRecord], deleting: [])
            let ckRecords = saveResults.compactMap { result in
                try? result.1.get()
            }
            let someRecords: [SomeRecord] = ckRecords.compactMap { SomeRecord(from: $0) }
            guard let modifiedRecord = someRecords.first else {
                throw CloudKitError.unexpectedResultFromServer
            }
            return modifiedRecord
        } catch {
            throw CloudKitError.invalidRequest
        }
    }
    
    init() async throws {
        do {
            try await authenticate()
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

