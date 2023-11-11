//
//  CloudKitService.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/11/23.
//

import Foundation

protocol DataStore {
    func fetchUsers() -> [String]
    func save(user: String)
}

class CloudKitService {
    private let dataStore: DataStore
    func save(user: String) {
        dataStore.save(user: user)
    }
    func fetchUsers() -> [String] {
        dataStore.fetchUsers()
    }
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
}
