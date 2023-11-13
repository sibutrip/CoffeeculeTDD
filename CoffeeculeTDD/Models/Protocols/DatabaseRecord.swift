//
//  DatabaseRecord.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/13/23.
//

import Foundation
import CloudKit

protocol DatabaseRecordable: Identifiable {
    associatedtype DatabaseRecord: DatabaseRecordable
    associatedtype FieldKey = Int
    var recordID: ID { get }
    var ckRecord: DatabaseRecord { get set }
}
