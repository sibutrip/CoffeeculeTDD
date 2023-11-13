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
    typealias CloudKitService = CoffeeculeTDD.CloudKitService<MockDataContainer>
    
    func test_init_succeedsIfUserHasCloudAccess() async throws {
        do {
            let _ = try await makeSUT()
            XCTAssert(true)
        } catch {
            XCTFail("CloudKitService init threw an error")
        }
    }
    
    func test_init_throwsAuthenticationErrorIfNoCloudAccess() async throws {
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
    
    func test_save_addsNewUserToStore() async throws {
        let sut = try await makeSUT()
        let newUser = User(name: "Cory")
        try await sut.save(record: newUser)
        let fetchedRecords: [User] = try await sut.fetch()
        XCTAssertEqual([newUser], fetchedRecords)
    }
    
    func test_save_throwsInvalidRequestIfRecordAlreadyExists() async throws {
        let sut = try await makeSUT()
        let newUser = User(name: "Cory")
        try await sut.save(record: newUser)
        do {
            try await sut.save(record: newUser)
        } catch CloudKitService.CloudKitError.invalidRequest {
            XCTAssert(true)
            return
        } catch {
            XCTFail("Threw incorrect error")
            return
        }
        XCTFail("Did not throw error when saving second record")
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
        
        let databaseUpdatedUser = try await sut.update(record: updatedUser, fields: [.name])
        
        
        XCTAssertEqual(updatedUser, databaseUpdatedUser)
    }
    
    func test_update_throwsInvalidRequestIfUserDoesntExist() async throws {
        let existingUsers = [
            User(name: "Cory"),
            User(name: "Tom"),
            User(name: "Zoe")
        ]
        let sut = try await makeSUT(with: existingUsers.map { $0.ckRecord })
        
        let newUser = User(name: "Tariq")
        do {
            let _ = try await sut.update(record: newUser, fields: [.name])
        } catch CloudKitService.CloudKitError.invalidRequest {
            XCTAssert(true)
            return
        } catch {
            XCTFail("Threw incorrect error when modifiying nonexistant record")
            return
        }
        XCTFail("update failed to throw error")
    }
    
    // MARK: - Helper Methods
    
    private func makeSUT(with ckRecords: [CKRecord] = [],
                 accountStatus: CKAccountStatus = .available,
                 userID: CKRecord.ID = .init(recordName: "test")) async throws -> CloudKitService {
        
        let database = MockDatabase(with: ckRecords)
        let mockDataContainer = MockDataContainer(with: database, userRecordID: userID, accountStatus: accountStatus)
        
        return try await CloudKitService(with: mockDataContainer)
    }
}

class MockDatabase: Database {
    
    private var records: [CKRecord] = []
    
    func save(_ record: CKRecord) async throws -> CKRecord {
        if records.contains(where: {$0.recordID == record.recordID }) {
            throw NSError()
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
        
        let saveResults: [Result<CKRecord, Error>] = savedRecords.map {
            .success($0)
        }
        let saveIDs = savedRecords.map { $0.recordID }
        let zippedSavedRecords = zip(saveIDs, saveResults)
        let saveResultsWithIDs = Dictionary(uniqueKeysWithValues: zippedSavedRecords)
        return (saveResults: saveResultsWithIDs, deleteResults: [:])
    }
    
    init(with records: [CKRecord] = []) {
        self.records = records
    }
}

extension CKDatabase.Scope {
    var recordID: CKRecord.ID {
        switch self {
        case .public:
            CKRecord.ID(recordName: "public")
        case .private:
            CKRecord.ID(recordName: "private")
        case .shared:
            CKRecord.ID(recordName: "shared")
        @unknown default:
            CKRecord.ID(recordName: "private")
        }
    }
}

class MockDataContainer: DataContainer {
    let `public`: Database
    
    private var userAccountStatus: CKAccountStatus
    private var userRecordID: CKRecord.ID

    func userRecordID() async throws -> CKRecord.ID {
        return userRecordID
    }

    func accountStatus() async throws -> CKAccountStatus {
        return self.userAccountStatus
    }
    
    init(with database: Database,
        userRecordID: CKRecord.ID,
         accountStatus: CKAccountStatus = .available) {
        self.userAccountStatus = accountStatus
        self.userRecordID = userRecordID
        self.public = database
    }
}
