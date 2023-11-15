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
    
    func test_save_addsNewRecordToStore() async throws {
        let sut = try await makeSUT()
        let mockRecord = MockRecord()
        _ = try await sut.save(record: mockRecord)
        let fetchedRecords: [MockRecord] = try await sut.fetch()
        XCTAssertEqual([mockRecord], fetchedRecords)
    }
    
    func test_save_throwsInvalidRequestIfRecordAlreadyExists() async throws {
        let sut = try await makeSUT()
        let mockRecord = MockRecord()
        _ = try await sut.save(record: mockRecord)
        do {
            _ = try await sut.save(record: mockRecord)
        } catch CloudKitService.CloudKitError.invalidRequest {
            XCTAssert(true)
            return
        } catch {
            XCTFail("Threw incorrect error")
            return
        }
        XCTFail("Did not throw error when saving second record")
    }
    
    func test_fetch_fetchesAllRecordsFromStore() async throws {
        let existingRecords = [
            MockRecord(),
            MockRecord(),
            MockRecord()
        ]
        let sut = try await makeSUT(with: existingRecords.map { $0.ckRecord })
        let fetchedRecords: [MockRecord] = try await sut.fetch()
        XCTAssertEqual(existingRecords, fetchedRecords)
    }
    
    func test_update_modifiesExistingRecord() async throws {
        let recordToModify = MockRecord()
        let existingRecords = [
            recordToModify,
            MockRecord(),
            MockRecord()
        ]
        let sut = try await makeSUT(with: existingRecords.map { $0.ckRecord })
        let newTestField1 = UUID().uuidString

        let updatedRecords = existingRecords.map { record in
            var record = record
            if record == recordToModify {
                record.testField1 = newTestField1
            }
            return record
        }
        let updatedRecord = updatedRecords.first { $0.testField1 == newTestField1 }!
        try await sut.update(record: updatedRecord)
        let databaseUpdatedRecords: [MockRecord] = try await sut.fetch()
        let databaseUpdatedRecord = databaseUpdatedRecords.filter { $0.id == updatedRecord.id }.first!
        XCTAssertEqual(updatedRecord, databaseUpdatedRecord)
    }
    
    func test_update_throwsInvalidRequestIfRecordDoesntExist() async throws {
        let existingRecords = [
            MockRecord(),
            MockRecord(),
            MockRecord()
        ]
        let sut = try await makeSUT(with: existingRecords.map { $0.ckRecord })
        
        let newRecord = MockRecord()
        do {
            let _ = try await sut.update(record: newRecord)
        } catch CloudKitService.CloudKitError.invalidRequest {
            XCTAssert(true)
            return
        } catch {
            XCTFail("Threw incorrect error when modifiying nonexistant record")
            return
        }
        XCTFail("update failed to throw error")
    }
    
    func test_children_fetchesAllChildrenOfParent() async throws {
        let existingParentRecord = MockRecord()
        let sut = try await makeSUT()
        let firstChildRecord = MockChildRecord(withParent: existingParentRecord)
        let secondChildRecord = MockChildRecord(withParent: existingParentRecord)
        try await sut.save(firstChildRecord, withParent: existingParentRecord)
        try await sut.save(secondChildRecord, withParent: existingParentRecord)
        let updatedChildRecords: [MockChildRecord] = try await sut.children(of: existingParentRecord)
        XCTAssertEqual(updatedChildRecords.count, 2)
    }
    
    func test_children_throwsIfNoParentFound() async throws {
        let parentRecord = MockRecord()
        let sut = try await makeSUT()
        do {
            let _: [MockChildRecord] = try await sut.children(of: parentRecord)
        } catch CloudKitService.CloudKitError.childRecordsNotFound {
            XCTAssert(true)
            return
        } catch {
            XCTFail("did not throw CloudKitError.childRecordsNotFound")
            return
        }
        XCTFail("did not throw an error")
    }
    
    // MARK: - Helper Methods
    
    private func makeSUT(with ckRecords: [CKRecord] = [],
                 accountStatus: CKAccountStatus = .available) async throws -> CloudKitService {
        
        let database = MockDatabase(with: ckRecords)
        let mockDataContainer = MockDataContainer(with: database, accountStatus: accountStatus)
        return try await CloudKitService(with: mockDataContainer)
    }
}
