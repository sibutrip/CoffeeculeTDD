//
//  CloudKitService.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/11/23.
//

import CloudKit

actor CloudKitService<Container: DataContainer> {
    private let container: Container
    private var coffeeculeID: String = ""
    private var userID: CKRecord.ID?
    
    
    lazy var database: Database = container.public
    
    private func assignCoffeeculeIdAndUserId() async throws {
        self.userID = try await container.userRecordID()
        let coffeecules: [Coffeecule] = try await fetch()
        if let coffecule = coffeecules.first {
            coffeeculeID = coffecule.coffeeculeIdentifier
        }
    }
    
    func updatedRecord<SomeRecord: Record>(for record: SomeRecord) async throws -> SomeRecord {
        do {
            let ckRecord = try await database.record(for: record.recordID)
            guard let record = SomeRecord(from: ckRecord) else {
                throw CloudKitError.couldNotCreateModelFromCkRecord
            }
            return record
        } catch {
            throw CloudKitError.recordDoesNotExist
        }
    }
    
    func authenticate() async throws {
        switch try await container.accountStatus() {
        case .available:
            do {
                try await assignCoffeeculeIdAndUserId()
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
        case invalidRequest, unexpectedResultFromServer, recordAlreadyExists, recordDoesNotExist, couldNotCreateModelFromCkRecord, childRecordsNotFound, userNotFound
    }
    
    func save<SomeRecord: Record>(record: SomeRecord) async throws -> SomeRecord{
        do {
            let ckRecord = record.ckRecord
            let returnedCkRecord = try await database.save(ckRecord)
            guard let record = SomeRecord(from: returnedCkRecord) else {
                throw CloudKitError.couldNotCreateModelFromCkRecord
            }
            return record
        } catch {
            throw CloudKitError.invalidRequest
        }
    }
    
    func fetch<SomeRecord: Record>() async throws -> [SomeRecord] {
        let (results,_) = try await database.records(
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
    
    func children<Child: ChildRecord, Parent: Record>(of parent: Parent) async throws -> [Child] where Child.Parent == Parent {
        let reference = CKRecord.Reference(recordID: parent.recordID, action: .none)
        let predicate = NSPredicate(format: "\(Parent.recordType) == %@", reference)
        let query = CKQuery(recordType: Child.recordType, predicate: predicate)
        
        let records = try await database.records(matching: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults)
        let unwrappedRecords = records.matchResults.compactMap { record in
            try? record.1.get()
        }
        if unwrappedRecords.isEmpty {
            throw CloudKitError.childRecordsNotFound
        }
        
        return unwrappedRecords.compactMap { record in
            Child(from: record, with: parent)
        }
    }
    
    func update<SomeRecord: Record>(record: SomeRecord) async throws {
        do {
            let (_,_) = try await database.modifyRecords(saving: [record.ckRecord], deleting: [])
        } catch {
            throw CloudKitError.invalidRequest
        }
    }
    
    func save<Child: ChildRecord, Parent: Record>(_ record: Child, withParent parent: Parent) async throws where Child.RecordKeys.AllCases == [Child.RecordKeys], Child.Parent == Parent {
        let childCkRecord = record.ckRecord
        childCkRecord.setValue(parent.reference, forKey: Parent.recordType)
        if record.creationDate == nil {
            let _ = try await database.save(childCkRecord)
        } else {
            _ = try await database.modifyRecords(saving: [childCkRecord], deleting: [])
        }
    }
    
    init(with container: Container) async throws {
        self.container = container
        try await authenticate()
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

