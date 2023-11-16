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
    
    func test_createCoffeecule_addsCoffeeculeToManagerIfSuccessful() async {
        let sut = await makeSUT(databaseActionSuccess: true)
        let coffeecules = sut.coffeecules
        XCTAssertEqual(1, coffeecules.count)
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
