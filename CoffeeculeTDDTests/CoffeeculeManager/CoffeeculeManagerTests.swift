//
//  UserManagerTests.swift
//  CoffeeculeTDDTests
//
//  Created by Cory Tripathy on 11/15/23.
//

import XCTest
import CloudKit
@testable import CoffeeculeTDD

@MainActor
final class UserManagerTests: XCTestCase {
    
    typealias UserManager = CoffeeculeTDD.CoffeeculeManager<MockCKService>
    typealias UserManagerError = UserManager.UserManagerError
    
    func test_init_assignsUserToUserManager() async {
        let sut = await makeSUT(didAuthenticate: true)
        let user = await sut.user
        XCTAssertNotNil(user)
    }
    
    func test_init_failsIfUserDoesNotHaveAccount() async {
        let sut = await makeSUT(didAuthenticate: false)
        let user = await sut.user
        XCTAssertNil(user)
    }
    
    func test_createCoffeecule_addsCoffeeculeToManagerIfSuccessful() async throws {
        let sut = await makeSUT(databaseActionSuccess: true)
        try await sut.createCoffeecule()
        let coffeecules = sut.coffeecules
        XCTAssertEqual(1, coffeecules.count)
    }
    
    func test_createCoffeecule_failsIfDidNotConnectToDatabase() async throws {
        let sut = await makeSUT(databaseActionSuccess: false)
        do {
            try await sut.createCoffeecule()
        } catch UserManagerError.failedToConnectToDatabase {
            XCTAssert(true)
            return
        } catch {
            XCTFail("createCoffeecule did not throw UserManagerError.failedToConnectToDatabase")
            return
        }
        XCTFail("createCoffeecule did not throw any errors")
    }
    
    func test_createCoffeecule_throwsIfNoCkServiceAvailable() async throws {
        let sut = await makeSUT(didAuthenticate: false, databaseActionSuccess: false)
        do {
            try await sut.createCoffeecule()
        } catch UserManagerError.noCkServiceAvailable {
            XCTAssertEqual(sut.coffeecules, [])
            return
        } catch {
            XCTFail("createCoffeecule did not throw UserManagerError.noCKServiceAvailable")
            return
        }
        XCTFail("createCoffeecule did not throw any errors")
    }
    
    func test_fetchCoffeecules_populatesManagerFromDatabase() async throws {
        let sut = await makeSUT()
        try await sut.fetchCoffeecules()
        XCTAssertEqual(sut.coffeecules.count, 4)
    }
    
    func test_fetchCoffeecules_failsIfCantConnectToDatabase() async throws {
        let sut = await makeSUT(didAuthenticate: true, databaseActionSuccess: false)
        do {
            try await sut.fetchCoffeecules()
        } catch UserManagerError.failedToConnectToDatabase {
            XCTAssertEqual(sut.coffeecules, [])
            return
        } catch {
            XCTFail("createCoffeecule did not throw UserManagerError.failedToConnectToDatabase")
            return
        }
        XCTFail("createCoffeecule did not throw any errors")
    }
    
    func test_fetchCoffeecules_throwsIfCKServiceNotAvailable() async throws {
        let sut = await makeSUT(didAuthenticate: false)
        do {
            try await sut.fetchCoffeecules()
        } catch UserManagerError.noCkServiceAvailable {
            XCTAssertEqual(sut.coffeecules, [])
            return
        } catch {
            XCTFail("createCoffeecule did not throw UserManagerError.noCKServiceAvailable")
            return
        }
        XCTFail("fetchCoffeecules did not throw any errors")
    }
    
    func test_fetchUsersInCoffeecule_addsUsersToManagerIfSuccessful() async throws {
        let sut = await makeSUT()
        sut.selectedCoffeecule = Coffeecule()
        try await sut.fetchUsersInCoffeecule()
        XCTAssertEqual(sut.usersInSelectedCoffeecule.count, 4)
    }
    
    func test_fetchUsersInCoffeecule_throwsNoCoffeeculeSelectedIfNoneSelected() async {
        let sut = await makeSUT()
        do {
            try await sut.fetchUsersInCoffeecule()
        } catch UserManagerError.noCoffeeculeSelected {
            XCTAssert(true)
            return
        } catch {
            XCTFail("fetchUsersInCoffeecule did not throw UserManagerError.noCoffeeculeSelected")
            return
        }
        XCTAssertEqual(sut.usersInSelectedCoffeecule, [])
    }
    
    func test_fetchUsersInCoffeecule_throwsIfFailedToConnectToDatabase() async {
        let sut = await makeSUT(databaseActionSuccess: false)
        sut.selectedCoffeecule = Coffeecule()
        do {
            try await sut.fetchUsersInCoffeecule()
        } catch UserManagerError.failedToConnectToDatabase {
            XCTAssert(true)
            return
        } catch {
            XCTFail("fetchUsersInCoffeecule did not throw UserManagerError.failedToConnectToDatabase")
            return
        }
        XCTFail("fetchUsersInCoffeecule did not throw any errors")
    }
    
    func test_addTransaction_addsTransactionToManagerIfSuccessful() async throws {
        let sut = await makeSUT()
        sut.selectedUsers = [
            User(systemUserID: UUID().uuidString),
            User(systemUserID: UUID().uuidString),
            User(systemUserID: UUID().uuidString)
        ]
        sut.usersInSelectedCoffeecule = sut.selectedUsers
        sut.selectedCoffeecule = Coffeecule()
        try sut.createUserRelationships()
        try await sut.addTransaction(withBuyer: sut.mostIndebttedFromSelectedUsers)
        XCTAssertEqual(sut.transactionsInSelectedCoffeecule.count, 2)
    }
    
    func test_addTransaction_throwsIfNoBuyerSelected() async throws {
        let sut = await makeSUT()
        sut.selectedUsers = [
            User(systemUserID: UUID().uuidString),
            User(systemUserID: UUID().uuidString),
            User(systemUserID: UUID().uuidString)
        ]
        sut.usersInSelectedCoffeecule = sut.selectedUsers
        sut.selectedCoffeecule = Coffeecule()
        try sut.createUserRelationships()
        do {
            try await sut.addTransaction(withBuyer: nil)
        } catch UserManagerError.noBuyerSelected {
            XCTAssert(true)
            return
        } catch {
            XCTFail("addTransaction did not throw UserManagerError.noBuyerSelected")
            return
        }
        XCTFail("addTransaction did not throw any errors")
    }
    
    func test_addTransaction_throwsIfNoCoffeeculeSelected() async throws {
        let sut = await makeSUT()
        sut.selectedUsers = [
            User(systemUserID: UUID().uuidString),
            User(systemUserID: UUID().uuidString),
            User(systemUserID: UUID().uuidString)
        ]
        sut.usersInSelectedCoffeecule = sut.selectedUsers
        try sut.createUserRelationships()
        do {
            try await sut.addTransaction(withBuyer: sut.mostIndebttedFromSelectedUsers)
        } catch UserManagerError.noCoffeeculeSelected {
            XCTAssert(true)
            return
        } catch {
            XCTFail("addTransaction did not throw UserManagerError.noCoffeeculeSelected")
            return
        }
        XCTFail("addTransaction did not throw any errors")
    }
    
    func test_addTransaction_throwsIfNoCkServiceAvailable() async throws {
        let sut = await makeSUT(didProvideCkService: false)
        sut.selectedUsers = [
            User(systemUserID: UUID().uuidString),
            User(systemUserID: UUID().uuidString),
            User(systemUserID: UUID().uuidString)
        ]
        sut.usersInSelectedCoffeecule = sut.selectedUsers
        try sut.createUserRelationships()
        do {
            try await sut.addTransaction(withBuyer: sut.mostIndebttedFromSelectedUsers)
        } catch UserManagerError.noCoffeeculeSelected {
            XCTAssert(true)
            return
        } catch {
            XCTFail("addTransaction did not throw UserManagerError.noCoffeeculeSelected")
            return
        }
        XCTFail("addTransaction did not throw any errors")
    }
    
    func test_addTransaction_throwsIfNoReceiverSelected() async throws {
        let sut = await makeSUT()
        sut.selectedCoffeecule = Coffeecule()
        do {
            try await sut.addTransaction(withBuyer: sut.mostIndebttedFromSelectedUsers)
        } catch UserManagerError.noReceiversSelected {
            XCTAssert(true)
            return
        } catch {
            XCTFail("addTransaction did not throw UserManagerError.noReceiversSelected")
            return
        }
        XCTFail("addTransaction did not throw any errors")
    }
    
    func test_addTransaction_throwsIfNoDatabaseAvailable() async throws {
        let sut = await makeSUT(databaseActionSuccess: false)
        sut.selectedUsers = [
            User(systemUserID: UUID().uuidString),
            User(systemUserID: UUID().uuidString),
            User(systemUserID: UUID().uuidString)
        ]
        sut.usersInSelectedCoffeecule = sut.selectedUsers
        sut.selectedCoffeecule = Coffeecule()
        try sut.createUserRelationships()
        do {
            try await sut.addTransaction(withBuyer: sut.mostIndebttedFromSelectedUsers)
        } catch UserManagerError.failedToConnectToDatabase {
            XCTAssert(true)
            return
        } catch {
            XCTFail("addTransaction did not throw UserManagerError.failedToConnectToDatabase")
            return
        }
        XCTFail("addTransaction did not throw any errors")
    }
    
    func test_fetchTransactionsInSelectedCoffeecule_populatesManagerWithTransactionsIfSuccessful() async throws {
        let sut = await makeSUT()
        sut.selectedCoffeecule = Coffeecule()
        try await sut.fetchTransactionsInCoffeecule()
        XCTAssertEqual(sut.transactionsInSelectedCoffeecule.count, 4)
    }
    
    func test_fetchTransactionsInSelectedCoffeecule_throwsIfNoCoffeeculeSelected() async throws {
        let sut = await makeSUT()
        do {
            try await sut.fetchTransactionsInCoffeecule()
        } catch UserManagerError.noCoffeeculeSelected {
            XCTAssert(true)
            return
        } catch {
            XCTFail("addTransaction did not throw UserManagerError.noCoffeeculeSelected")
            return
        }
        XCTFail("addTransaction did not throw any errors")
    }
    
    func test_fetchTransactionsInSelectedCoffeecule_throwsIfNoCkServiceAvailable() async throws {
        let sut = await makeSUT(didProvideCkService: false)
        sut.selectedCoffeecule = Coffeecule()
        do {
            try await sut.fetchTransactionsInCoffeecule()
        } catch UserManagerError.noCkServiceAvailable {
            XCTAssert(true)
            return
        } catch {
            XCTFail("addTransaction did not throw UserManagerError.noCkServiceAvailable")
            return
        }
        XCTFail("addTransaction did not throw any errors")
    }
    
    func test_createUserRelationships_populatesManagerIfSuccessful() async throws {
        let sut = await makeSUT()
        let firstUser = User(systemUserID: "firstUser")
        let secondUser = User(systemUserID: "secondUser")
        let thirdUser = User(systemUserID: "thirdUser")
        let coffeecule = Coffeecule()
        let transactions: [Transaction] = [
            Transaction(buyer: firstUser, receiver: secondUser, in: coffeecule),
            Transaction(buyer: firstUser, receiver: secondUser, in: coffeecule),
            Transaction(buyer: secondUser, receiver: thirdUser, in: coffeecule),
            Transaction(buyer: secondUser, receiver: firstUser, in: coffeecule),
            Transaction(buyer: thirdUser, receiver: firstUser, in: coffeecule)
        ]
        sut.usersInSelectedCoffeecule = [firstUser, secondUser, thirdUser]
        sut.transactionsInSelectedCoffeecule = transactions
        try sut.createUserRelationships()
        XCTAssertEqual(sut.userRelationships[thirdUser]?[firstUser], 1) // third user is owed 1 coffee by 1st user
        XCTAssertEqual(sut.userRelationships[thirdUser]?[secondUser], -1)
        XCTAssertEqual(sut.userRelationships[secondUser]?[firstUser], -1)
        XCTAssertEqual(sut.userRelationships[secondUser]?[thirdUser], 1)
        XCTAssertEqual(sut.userRelationships[firstUser]?[thirdUser], -1)
        XCTAssertEqual(sut.userRelationships[firstUser]?[secondUser], 1)
    }
    
    func test_createUserRelationships_throwsIfNoUsersFound() async throws {
        let sut = await makeSUT()
        do {
            try sut.createUserRelationships()
        } catch UserManagerError.noUsersFound {
            XCTAssert(true)
            return
        } catch {
            XCTFail("createUserRelationships did not throw UserManagerError.noUsersFound")
            return
        }
        XCTFail("addTransaction did not throw any errors")
    }
    
    func test_createUserRelationships_throwsIfTransactionDoesNotHaveBuyerAndReceiver() async throws {
        let sut = await makeSUT()
        sut.usersInSelectedCoffeecule = [User(systemUserID: "Test")]
        let transactions: [Transaction] = [
            Transaction(from: CKRecord(recordType: "Test"), with: User(systemUserID: "Test"))!
        ]
        sut.transactionsInSelectedCoffeecule = transactions
        do {
            try sut.createUserRelationships()
        } catch UserManagerError.invalidTransactionFormat {
            XCTAssert(true)
            return
        } catch {
            XCTFail("createUserRelationships did not throw UserManagerError.invalidTransactionFormat")
            return
        }
        XCTFail("addTransaction did not throw any errors")
    }
    
    // MARK: - Helper methods
    
    private func makeSUT(didAuthenticate: Bool = true,
                         databaseActionSuccess: Bool = true,
                         didProvideCkService: Bool = true) async -> UserManager {
        let userManager = UserManager()
        if didProvideCkService {
            let mockCkService = await MockCKService(didAuthenticate: didAuthenticate, databaseActionSuccess: databaseActionSuccess)
            userManager.ckService = mockCkService
        }
        return userManager
    }
}

extension XCTestCase {
    func wait(interval: TimeInterval = 0.1 , completion: @escaping (() -> Void)) {
        let exp = expectation(description: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            completion()
            exp.fulfill()
        }
        waitForExpectations(timeout: interval + 0.1) // add 0.1 for sure `asyncAfter` called
    }
}
