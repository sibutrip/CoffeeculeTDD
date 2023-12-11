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
        let user = sut.user
        XCTAssertNotNil(user)
    }
    
    func test_init_failsIfUserDoesNotHaveAccount() async {
        let sut = await makeSUT(didAuthenticate: false)
        let user = sut.user
        XCTAssertNil(user)
    }
    
    func test_createCoffeecule_addsCoffeeculeToManagerIfSuccessful() async throws {
        let sut = await makeSUT(databaseActionSuccess: true)
        try await sut.createCoffeecule(with: "Test")
        let coffeecules = sut.coffeecules
        XCTAssertEqual(1, coffeecules.count)
    }
    
    func test_createCoffeecule_failsIfDidNotConnectToDatabase() async throws {
        let sut = await makeSUT(databaseActionSuccess: false)
        do {
            try await sut.createCoffeecule(with: "Test")
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
            try await sut.createCoffeecule(with: "Test")
        } catch UserManagerError.noCkServiceAvailable {
            XCTAssertEqual(sut.coffeecules, [])
            return
        } catch {
            XCTFail("createCoffeecule did not throw UserManagerError.noCKServiceAvailable")
            return
        }
        XCTFail("createCoffeecule did not throw any errors")
    }
    
    func test_createCoffeecule_throwsIfCoffeeculeNameExistsLocally() async throws {
        let sut = await makeSUT()
        sut.coffeecules.append(Coffeecule(with: "CorysCule"))
        do {
            try await sut.createCoffeecule(with: "CorysCule")
        } catch UserManagerError.coffeeculeNameTaken {
            XCTAssert(true)
            return
        } catch {
            XCTFail("createCoffeecule did not throw UserManagerError.coffeeculeNameTaken")
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
    
    func test_fetchUsersInCoffeecule_addsUserPlusUsersToManagerIfSuccessful() async throws {
        let sut = await makeSUT()
        sut.selectedCoffeecule = Coffeecule(with: "Test")
        try await sut.fetchUsersInCoffeecule()
        XCTAssertEqual(sut.usersInSelectedCoffeecule.count, 5)
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
        sut.selectedCoffeecule = Coffeecule(with: "Test")
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
        sut.selectedCoffeecule = Coffeecule(with: "Test")
        try sut.createUserRelationships()
        try await sut.addTransaction()
        XCTAssertEqual(sut.transactionsInSelectedCoffeecule.count, 2)
    }
    
    func test_addTransaction_throwsIfNoBuyerSelected() async throws {
        let sut = await makeSUT()
        sut.selectedUsers = [
            User(systemUserID: UUID().uuidString)
        ]
        sut.usersInSelectedCoffeecule = sut.selectedUsers
        sut.selectedCoffeecule = Coffeecule(with: "Test")
        try sut.createUserRelationships()
        do {
            try await sut.addTransaction()
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
            try await sut.addTransaction()
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
            try await sut.addTransaction()
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
        sut.selectedCoffeecule = Coffeecule(with: "Test")
        do {
            try await sut.addTransaction()
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
        sut.selectedCoffeecule = Coffeecule(with: "Test")
        try sut.createUserRelationships()
        do {
            try await sut.addTransaction()
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
        sut.selectedCoffeecule = Coffeecule(with: "Test")
        try await sut.fetchTransactionsInCoffeecule()
        XCTAssertEqual(sut.transactionsInSelectedCoffeecule.count, 2)
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
        sut.selectedCoffeecule = Coffeecule(with: "Test")
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
        let coffeecule = Coffeecule(with: "Test")
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
    
    func test_remove_removesTransactionFromTransactionsInSelectedCoffeecule() async throws {
        let sut = await makeSUT()
        let coffeecule = Coffeecule(with: "Test")
        let buyer = User(systemUserID: "Test")
        let receiver = User(systemUserID: "Test2")
        let existingTransactions = [
            Transaction(buyer: buyer, receiver: receiver, in: coffeecule),
            Transaction(buyer: buyer, receiver: receiver, in: coffeecule)]
        sut.transactionsInSelectedCoffeecule = existingTransactions
        try await sut.remove(existingTransactions[0])
        XCTAssertEqual(sut.transactionsInSelectedCoffeecule[0], existingTransactions[1])
    }
    
    func test_remove_throwsIfNoCkServiceAvailable() async throws {
        let sut = await makeSUT(didProvideCkService: false)
        let coffeecule = Coffeecule(with: "Test")
        let buyer = User(systemUserID: "Test")
        let receiver = User(systemUserID: "Test2")
        let existingTransactions = [
            Transaction(buyer: buyer, receiver: receiver, in: coffeecule),
            Transaction(buyer: buyer, receiver: receiver, in: coffeecule)]
        sut.transactionsInSelectedCoffeecule = existingTransactions
        do {
            try await sut.remove(existingTransactions[0])
        } catch UserManagerError.noCkServiceAvailable {
            XCTAssert(true)
            return
        } catch {
            XCTFail("addTransaction did not throw UserManagerError.noCkServiceAvailable")
            return
        }
        XCTFail("addTransaction did not throw any errors")
    }
    
    func test_update_updatesLocalUserIfSuccessful() async throws {
        let sut = await makeSUT()
        sut.usersInSelectedCoffeecule = [sut.user!]
        var modifiedUser = sut.user!
        modifiedUser.userColorString = "orange"
        
        try await sut.update(modifiedUser)
        
        XCTAssertEqual(sut.user?.userColor, UserColor.orange)
        XCTAssertEqual(sut.usersInSelectedCoffeecule.first(where: {$0.id == modifiedUser.id})!.userColor, UserColor.orange)
    }
    
    func test_update_updatesLocalUserIfNoDatabse() async throws {
        let sut = await makeSUT(databaseActionSuccess: false)
        sut.usersInSelectedCoffeecule = [sut.user!]
        var modifiedUser = sut.user!
        modifiedUser.userColorString = "orange"
        do {
            try await sut.update(modifiedUser)
        } catch { }
        
        XCTAssertEqual(sut.user?.userColor, UserColor.orange)
        XCTAssertEqual(sut.usersInSelectedCoffeecule.first(where: {$0.id == modifiedUser.id})!.userColor, UserColor.orange)
    }
    
    func test_update_throwsNoUserIfNoCKService() async throws {
        let sut = await makeSUT(didProvideCkService: false)
        do {
            try await sut.update(sut.user)
        } catch UserManagerError.noUsersFound {
            XCTAssert(true)
            return
        } catch {
            XCTFail("addTransaction did not throw UserManagerError.noUsersFound")
            return
        }
        XCTFail("addTransaction did not throw any errors")
    }
    
    func test_updateTransactions_updatesTransactionsInSelectedCoffeecule() async {
        let sut = await makeSUT()
        let coffeecule = Coffeecule(with: "Test")
        let firstUser = sut.user!
        let secondUser = User(systemUserID: UUID().uuidString)
        sut.transactionsInSelectedCoffeecule = [Transaction(buyer: firstUser, receiver: secondUser, in: coffeecule)]
        var modifiedUser = sut.user!
        modifiedUser.name = "Cornelius the Great"
        
        sut.updateTransactions(withNewNameFrom: modifiedUser)
        
        XCTAssertEqual(sut.transactionsInSelectedCoffeecule.first!.secondParent?.name, modifiedUser.name)
    }
    
    func test_updateTransactions_updatesTransactionsWithNewUserName() async {
        let sut = await makeSUT()
        let coffeecule = Coffeecule(with: "Test")
        sut.selectedCoffeecule = coffeecule
        let secondUser = User(systemUserID: UUID().uuidString)
        
        let transactions = [
            Transaction(buyer: sut.user!, receiver: secondUser, in: coffeecule),
            Transaction(buyer: secondUser, receiver: sut.user!, in: coffeecule)
        ]
        sut.transactionsInSelectedCoffeecule = transactions
        
        var userWithNewName = sut.user!
        userWithNewName.name = "New Name"
        sut.updateTransactions(withNewNameFrom: userWithNewName)
        
        let updatedTransactions = sut.transactionsInSelectedCoffeecule
        let newUserNameFromTransactions = [updatedTransactions[0].secondParent!.name, updatedTransactions[1].thirdParent!.name]
        XCTAssertEqual(newUserNameFromTransactions, [userWithNewName.name, userWithNewName.name])
    }
    
    func test_updateTransactions_keepsNewNameIfNameNotChanged() async {
        let sut = await makeSUT()
        let coffeecule = Coffeecule(with: "Test")
        sut.selectedCoffeecule = coffeecule
        let secondUser = User(systemUserID: UUID().uuidString)
        
        let transactions = [
            Transaction(buyer: sut.user!, receiver: secondUser, in: coffeecule),
            Transaction(buyer: secondUser, receiver: sut.user!, in: coffeecule)
        ]
        sut.transactionsInSelectedCoffeecule = transactions
        sut.updateTransactions(withNewNameFrom: sut.user!)
        
        let updatedTransactions = sut.transactionsInSelectedCoffeecule
        let newUserNameFromTransactions = [updatedTransactions[0].secondParent!.name, updatedTransactions[1].thirdParent!.name]
        XCTAssertEqual(newUserNameFromTransactions, [sut.user!.name, sut.user!.name])
    }
    
    func test_updateTransactions_doesNotChangeTransactionsIfUserNotInCoffeecule() async {
        let sut = await makeSUT()
        let coffeecule = Coffeecule(with: "Test")
        sut.selectedCoffeecule = coffeecule
        let secondUser = User(systemUserID: UUID().uuidString)
        
        let transactions = [
            Transaction(buyer: sut.user!, receiver: secondUser, in: coffeecule),
            Transaction(buyer: secondUser, receiver: sut.user!, in: coffeecule)
        ]
        sut.transactionsInSelectedCoffeecule = transactions
        sut.updateTransactions(withNewNameFrom: sut.user!)
        
        let updatedTransactions = sut.transactionsInSelectedCoffeecule
        let newUserNameFromTransactions = [updatedTransactions[0].secondParent!.name, updatedTransactions[1].thirdParent!.name]
        XCTAssertEqual(newUserNameFromTransactions, [sut.user!.name, sut.user!.name])
    }
    
    func test_joinCoffeecule_setsSelectedCoffeeculeToFetchedCoffeeculeOnSuccess() async throws {
        let sut = await makeSUT()
        var coffeecule = Coffeecule(with: "Test")
        coffeecule.inviteCode = "123123"
        sut.joinCoffeecule(withInviteCode: <#T##String#>)
    }
    
//    func joinCoffeecule(withInviteCode inviteCode: String) async throws {
//        guard let user else { throw UserManagerError.noUsersFound }
//        guard let ckService else { throw UserManagerError.noCkServiceAvailable }
//        guard let fetchedCoffeecules: [Coffeecule] = try? await ckService.records(matchingValue: inviteCode, inField: .inviteCode) else {
//            throw UserManagerError.noCoffeeculeFound
//        }
//        guard let fetchedCoffeecule = fetchedCoffeecules.first else {
//            throw UserManagerError.noCoffeeculeFound
//        }
//        let relationship = Relationship(user: user, coffecule: fetchedCoffeecule)
//        do {
//            _ = try await ckService.update(record: user, updatingFields: [.name])
//            try await ckService.saveWithTwoParents(relationship)
//            self.coffeecules.append(fetchedCoffeecule)
//            self.selectedCoffeecule = fetchedCoffeecule
//        } catch {
//            throw UserManagerError.failedToConnectToDatabase
//        }
//    }
    
    // MARK: - Helper methods
    
    private func makeSUT(didAuthenticate: Bool = true,
                         databaseActionSuccess: Bool = true,
                         didProvideCkService: Bool = true) async -> UserManager {
        let userManager = UserManager()
        if didProvideCkService {
            let mockCkService = await MockCKService(didAuthenticate: didAuthenticate, databaseActionSuccess: databaseActionSuccess)
            userManager.ckService = mockCkService
            userManager.user = await mockCkService.user
            if databaseActionSuccess {
                userManager.usersInSelectedCoffeecule = mockCkService.usersInSelectedCoffeecule
            }
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
