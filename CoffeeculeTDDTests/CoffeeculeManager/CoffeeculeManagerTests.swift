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
    
    typealias UserManager = CoffeeculeTDD.UserManager<MockCKService>
    
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
        } catch UserManager.UserManagerError.failedToConnectToDatabase {
            XCTAssert(true)
            return
        } catch {
            XCTFail("createCoffeecule did not throw UserManagerError.failedToConnectToDatabase")
            return
        }
        XCTFail("createCoffeecule did not throw any errors")
    }
    
    func test_createCoffeecule_failsIfNoCkServiceAvailable() async throws {
        let sut = await makeSUT(didAuthenticate: false, databaseActionSuccess: false)
        do {
            try await sut.createCoffeecule()
        } catch UserManager.UserManagerError.noCKServiceAvailable {
            XCTAssert(true)
            return
        } catch {
            XCTFail("createCoffeecule did not throw UserManagerError.noCKServiceAvailable")
            return
        }
        XCTFail("createCoffeecule did not throw any errors")
    }
    
    // MARK: - Helper methods
    
    private func makeSUT(didAuthenticate: Bool = true, databaseActionSuccess: Bool = true) async -> UserManager {
        let mockCkService = await MockCKService(didAuthenticate: didAuthenticate, databaseActionSuccess: databaseActionSuccess)
        let userManager = UserManager()
        userManager.ckService = mockCkService
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
