//
//  DataContainer.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/12/23.
//

import CloudKit

protocol DataContainer {
    func userRecordID() async throws -> CKRecord.ID
    func accountStatus() async throws -> CKAccountStatus
    var `public`: Database { get }
}

