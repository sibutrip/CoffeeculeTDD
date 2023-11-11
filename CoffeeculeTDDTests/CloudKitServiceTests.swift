//
//  CloudKitServiceTests.swift
//  CoffeeculeTDDTests
//
//  Created by Cory Tripathy on 11/11/23.
//

import XCTest
import CloudKit
@testable import CoffeeculeTDD

final class CloudKitServiceTests: XCTestCase {
    func test_save_addsNewUserToStore() async throws {
        let sut = try await makeSUT()
        let newUser = User(name: "Cory")
        try await sut.save(record: newUser)
        let fetchedRecords: [User] = try await sut.fetch()
        XCTAssertEqual([newUser], fetchedRecords)
    }
    
    func test_save_failsIfNoCloudAccess() async throws {
        do {
            let _ = try await makeSUT(accountStatus: .noAccount)
            XCTFail("CloudKitService init did not throw an error")
        } catch {
            guard let authenticationError = error as? CloudKitService.AuthenticationError else {
                XCTFail("CloudKit Service threw an error, but it was not an Authentication Error")
                return
            }
            XCTAssert(CloudKitService.AuthenticationError.allCases.contains([authenticationError]))
        }
    }
    
    func test_fetch_fetchesAllUsersFromStore() async throws {
        let existingUsers = [
            User(name: "Cory"),
            User(name: "Tom"),
            User(name: "Zoe")
        ]
        let sut = try await makeSUT(with: existingUsers.map { $0.ckRecord })
        let fetchedUsers: [User] = try await sut.fetch()
        XCTAssertEqual(existingUsers, fetchedUsers)
    }
    
    func test_update_modifiesExistingUser() async throws {
        let existingUsers = [
            User(name: "Cory"),
            User(name: "Tom"),
            User(name: "Zoe")
        ]
        let sut = try await makeSUT(with: existingUsers.map { $0.ckRecord })

        let updatedUsers = existingUsers.map { user in
            var user = user
            if user.name == "Cory" {
                user.name = "Cory T."
                return user
            }
            return user
        }
        let updatedUser = updatedUsers.first { $0.name == "Cory T." }!
        
        let dataStoreUpdatedUser = try await sut.update(record: updatedUser, fields: [.name])
        
        
        XCTAssertEqual(updatedUser, dataStoreUpdatedUser)
    }
    
    // MARK: - Helper Methods
    
    func makeSUT(with ckRecords: [CKRecord] = [], accountStatus: CKAccountStatus = .available) async throws -> CloudKitService {
        let dataStore = MockDataStore(with: ckRecords, accountStatus: accountStatus)
        return try await CloudKitService(dataStore: dataStore)
    }
}

class MockDataStore: DataStore {
    func userRecordID() async throws -> CKRecord.ID {
        return .init(recordName: "TestRecord")
    }
    
    func accountStatus() async throws -> CKAccountStatus {
        return self.userAccountStatus
    }
    
    func save(_ record: CKRecord) async throws -> CKRecord {
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
        let saveResults: [Result<CKRecord, Error>] = savedRecords.map {
            .success($0)
        }
        let saveIDs = savedRecords.map { $0.recordID }
        let zippedSavedRecords = zip(saveIDs, saveResults)
        let saveResultsWithIDs = Dictionary(uniqueKeysWithValues: zippedSavedRecords)
        return (saveResults: saveResultsWithIDs, deleteResults: [:])
    }
    
    private var userAccountStatus: CKAccountStatus = .available
    private var records: [CKRecord] = []
    
    init(with records: [CKRecord] = [], accountStatus: CKAccountStatus) {
        self.records = records
        self.userAccountStatus = accountStatus
    }
}
