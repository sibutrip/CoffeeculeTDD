//
//  CloudKitServiceTests.swift
//  CoffeeculeTDDTests
//
//  Created by Cory Tripathy on 11/11/23.
//

import XCTest
@testable import CoffeeculeTDD

final class CloudKitServiceTests: XCTestCase {
    func test_save_addsNewUserToStore() {
        let dataStore = MockDataStore()
        let sut = CloudKitService(dataStore: dataStore)
        let newUser = "Cory"
        sut.save(user: newUser)
        XCTAssertEqual([newUser], sut.fetchUsers())
    }
    
    func test_fetchUsers_fetchesAllUsersFromStore() {
        let existingUsers = ["Cory", "Tom", "Zoe"]
        let dataStore = MockDataStore(users: existingUsers)
        let sut = CloudKitService(dataStore: dataStore)
        XCTAssertEqual(existingUsers, sut.fetchUsers())
    }
    
}

class MockDataStore: DataStore {
    private var users: [String] = []
    
    func fetchUsers() -> [String] {
        return users
    }
    
    func save(user: String) {
        users.append(user)
    }
    
    init(users: [String] = []) {
        self.users = users
    }
}
