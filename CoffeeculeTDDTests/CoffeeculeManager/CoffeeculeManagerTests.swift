//
//  UserManagerTests.swift
//  CoffeeculeTDDTests
//
//  Created by Cory Tripathy on 11/15/23.
//

import XCTest
@testable import CoffeeculeTDD

final class UserManagerTests: XCTestCase {
    func test_init_assignsUserToUserManager() {
        let sut = UserManager(with: MockDataContainer(with: MockDatabase(), accountStatus: .available))
        wait(interval: 1) {
            XCTAssertNotNil(sut.user)
        }
    }
    func test_init_failsIfUserDoesNotHaveAccount() {
        let sut = UserManager(with: MockDataContainer(with: MockDatabase(), accountStatus: .noAccount))
        wait {
            XCTAssertNotNil(sut.displayedError)
        }
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
